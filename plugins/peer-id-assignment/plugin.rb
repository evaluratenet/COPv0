# name: peer-id-assignment
# about: Assigns and manages fixed anonymous Peer IDs for Circle of Peers platform
# version: 1.0.0
# authors: Circle of Peers Team
# url: https://github.com/circleofpeers/discourse-peer-id

register_asset 'stylesheets/peer-id.scss'

enabled_site_setting :peer_id_enabled

after_initialize do
  # Load the plugin's models and controllers
  load File.expand_path('../models/peer_id.rb', __FILE__)
  load File.expand_path('../controllers/peer_ids_controller.rb', __FILE__)
  load File.expand_path('../jobs/assign_peer_id.rb', __FILE__)
  load File.expand_path('../jobs/update_peer_display.rb', __FILE__)
  
  # Add routes
  Discourse::Application.routes.append do
    get '/admin/peer-ids' => 'peer_ids#index'
    post '/admin/peer-ids/assign' => 'peer_ids#assign'
    put '/admin/peer-ids/:id' => 'peer_ids#update'
    delete '/admin/peer-ids/:id' => 'peer_ids#destroy'
  end
  
  # Add admin panel
  add_admin_route 'peer_ids.title', 'peer_ids'
  
  # Hook into user approval process
  on(:user_approved) do |user|
    Jobs.enqueue(:assign_peer_id, user_id: user.id)
  end
  
  # Hook into post creation to anonymize usernames
  on(:post_created) do |post|
    if post.user && post.user.custom_fields['peer_id']
      Jobs.enqueue(:update_peer_display, post_id: post.id)
    end
  end
  
  # Add custom fields to user serializer
  add_to_serializer(:user, :peer_id) do
    object.custom_fields['peer_id']
  end
  
  # Override username display in posts
  module ::PeerId
    class Engine < ::Rails::Engine
      engine_name "peer_id"
      isolate_namespace PeerId
    end
  end
  
  # Add to admin panel
  Admin::PeerIdsController.class_eval do
    def index
      render_serialized(PeerId.all, AdminPeerIdSerializer)
    end
    
    def assign
      user = User.find(params[:user_id])
      peer_id = PeerId.assign_to_user(user)
      render json: { peer_id: peer_id }
    end
    
    def update
      peer_id = PeerId.find(params[:id])
      peer_id.update(peer_id_params)
      render json: { success: true }
    end
    
    def destroy
      peer_id = PeerId.find(params[:id])
      peer_id.destroy
      render json: { success: true }
    end
    
    private
    
    def peer_id_params
      params.require(:peer_id).permit(:display_name, :status)
    end
  end
end

# Database migration
class AddPeerIdTables < ActiveRecord::Migration[7.0]
  def up
    create_table :peer_ids do |t|
      t.integer :user_id, null: false
      t.string :peer_number, null: false
      t.string :display_name, null: false
      t.string :status, default: 'active'
      t.datetime :assigned_at, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    
    add_index :peer_ids, :user_id, unique: true
    add_index :peer_ids, :peer_number, unique: true
    add_index :peer_ids, :display_name, unique: true
    
    # Add custom field to users table
    add_column :users, :peer_id, :string
    
    # Create peer_id_assignments table for tracking
    create_table :peer_id_assignments do |t|
      t.integer :user_id, null: false
      t.string :peer_number, null: false
      t.string :assigned_by, null: false
      t.text :notes
      t.datetime :created_at, null: false
    end
    
    add_index :peer_id_assignments, :user_id
    add_index :peer_id_assignments, :peer_number
  end
  
  def down
    drop_table :peer_ids
    drop_table :peer_id_assignments
    remove_column :users, :peer_id
  end
end 