# name: ai-moderation
# about: AI-powered content moderation and user flagging system for Circle of Peers
# version: 1.0.0
# authors: Circle of Peers Team
# url: https://github.com/circleofpeers/discourse-ai-moderation

register_asset 'stylesheets/ai-moderation.scss'

enabled_site_setting :ai_moderation_enabled

after_initialize do
  # Load the plugin's models and controllers
  load File.expand_path('../models/post_flag.rb', __FILE__)
  load File.expand_path('../models/violation_type.rb', __FILE__)
  load File.expand_path('../controllers/flags_controller.rb', __FILE__)
  load File.expand_path('../jobs/process_ai_moderation.rb', __FILE__)
  load File.expand_path('../jobs/notify_admin_of_flag.rb', __FILE__)
  
  # Add routes
  Discourse::Application.routes.append do
    get '/admin/flags' => 'flags#index'
    get '/admin/flags/:id' => 'flags#show'
    put '/admin/flags/:id' => 'flags#update'
    delete '/admin/flags/:id' => 'flags#destroy'
    post '/admin/flags/:id/approve' => 'flags#approve'
    post '/admin/flags/:id/reject' => 'flags#reject'
    post '/admin/flags/:id/suspend_user' => 'flags#suspend_user'
  end
  
  # Add admin panel
  add_admin_route 'flags.title', 'flags'
  
  # Hook into post creation for AI moderation
  on(:post_created) do |post|
    Jobs.enqueue(:process_ai_moderation, post_id: post.id)
  end
  
  # Hook into post editing for re-moderation
  on(:post_edited) do |post|
    Jobs.enqueue(:process_ai_moderation, post_id: post.id)
  end
  
  # Add flag button to posts
  add_to_serializer(:post, :can_flag) do
    object.user_id != scope&.user&.id
  end
  
  # Add violation types to post serializer
  add_to_serializer(:post, :violation_types) do
    ViolationType.all.map { |vt| { id: vt.id, name: vt.name, description: vt.description } }
  end
  
  # Override post actions to include flagging
  module ::AiModeration
    class Engine < ::Rails::Engine
      engine_name "ai_moderation"
      isolate_namespace AiModeration
    end
  end
  
  # Add flagging action to posts
  PostActionType.types[:flag_violation] = 10
  
  # Add custom post action
  module PostActionCreator
    def self.create(creator, post, post_action_type_id, opts = {})
      if post_action_type_id == PostActionType.types[:flag_violation]
        create_violation_flag(creator, post, opts)
      else
        super
      end
    end
    
    def self.create_violation_flag(creator, post, opts)
      violation_type_id = opts[:violation_type_id]
      reason = opts[:reason]
      
      # Create the flag
      flag = PostFlag.create!(
        post_id: post.id,
        flagged_by_user_id: creator.id,
        flagged_by_peer_id: creator.custom_fields['peer_id'],
        violation_type_id: violation_type_id,
        reason: reason,
        source: 'user',
        status: 'pending'
      )
      
      # Notify admin
      Jobs.enqueue(:notify_admin_of_flag, flag_id: flag.id)
      
      # Return success
      { success: true, flag_id: flag.id }
    end
  end
end

# Database migration
class AddModerationTables < ActiveRecord::Migration[7.0]
  def up
    create_table :violation_types do |t|
      t.string :name, null: false
      t.text :description
      t.integer :severity, default: 1
      t.boolean :ai_detectable, default: true
      t.boolean :user_reportable, default: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    
    add_index :violation_types, :name, unique: true
    
    create_table :post_flags do |t|
      t.integer :post_id, null: false
      t.integer :flagged_by_user_id
      t.string :flagged_by_peer_id
      t.integer :violation_type_id, null: false
      t.text :reason
      t.string :source, null: false  # 'user', 'ai', 'admin'
      t.string :status, default: 'pending'  # 'pending', 'approved', 'rejected', 'resolved'
      t.integer :reviewed_by_admin_id
      t.datetime :reviewed_at
      t.text :admin_notes
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    
    add_index :post_flags, :post_id
    add_index :post_flags, :flagged_by_user_id
    add_index :post_flags, :violation_type_id
    add_index :post_flags, :status
    add_index :post_flags, :source
    
    # Add custom field to posts for flag count
    add_column :posts, :flag_count, :integer, default: 0
    add_column :posts, :last_flagged_at, :datetime
    
    # Seed violation types
    seed_violation_types
  end
  
  def down
    drop_table :post_flags
    drop_table :violation_types
    remove_column :posts, :flag_count
    remove_column :posts, :last_flagged_at
  end
  
  private
  
  def seed_violation_types
    violation_types = [
      { name: 'solicitation', description: 'Promotion or sales content', severity: 3 },
      { name: 'pii', description: 'Personal identifiable information', severity: 4 },
      { name: 'harassment', description: 'Hostile or inappropriate tone', severity: 5 },
      { name: 'confidential', description: 'Company confidential information', severity: 4 },
      { name: 'off_topic', description: 'Content unrelated to discussion', severity: 2 },
      { name: 'spam', description: 'Repeated or automated content', severity: 3 },
      { name: 'identity_leak', description: 'Revealing personal identity', severity: 4 },
      { name: 'inappropriate', description: 'Inappropriate content for professional forum', severity: 3 }
    ]
    
    violation_types.each do |vt|
      ViolationType.create!(vt)
    end
  end
end 