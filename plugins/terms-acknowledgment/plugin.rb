# name: terms-acknowledgment
# about: Handles Terms and Conditions acknowledgment during user signup
# version: 1.0.0
# authors: Circle of Peers Team
# url: https://github.com/circleofpeers/discourse-terms-acknowledgment

register_asset 'stylesheets/terms-acknowledgment.scss'

enabled_site_setting :terms_acknowledgment_enabled

after_initialize do
  # Load the plugin's models and controllers
  load File.expand_path('../models/terms_acknowledgment.rb', __FILE__)
  load File.expand_path('../controllers/terms_controller.rb', __FILE__)
  
  # Add routes
  Discourse::Application.routes.append do
    get '/terms' => 'terms#show'
    post '/terms/acknowledge' => 'terms#acknowledge'
    get '/terms/status' => 'terms#status'
  end
  
  # Hook into user registration
  on(:user_created) do |user|
    # Check if user acknowledged terms
    unless TermsAcknowledgment.find_by(user_id: user.id)
      # Create pending acknowledgment record
      TermsAcknowledgment.create!(
        user_id: user.id,
        status: 'pending',
        terms_version: current_terms_version
      )
    end
  end
  
  # Hook into user approval
  on(:user_approved) do |user|
    # Ensure terms acknowledgment is complete
    acknowledgment = TermsAcknowledgment.find_by(user_id: user.id)
    if acknowledgment && acknowledgment.status == 'pending'
      # Send reminder email
      Jobs.enqueue(:terms_reminder_email, user_id: user.id)
    end
  end
  
  # Add to user serializer
  add_to_serializer(:user, :terms_acknowledged) do
    acknowledgment = TermsAcknowledgment.find_by(user_id: object.id)
    acknowledgment&.status == 'acknowledged'
  end
  
  # Add to user serializer
  add_to_serializer(:user, :terms_acknowledgment_required) do
    acknowledgment = TermsAcknowledgment.find_by(user_id: object.id)
    acknowledgment&.status == 'pending'
  end
  
  # Override registration form
  module ::TermsAcknowledgment
    class Engine < ::Rails::Engine
      engine_name "terms_acknowledgment"
      isolate_namespace TermsAcknowledgment
    end
  end
  
  # Add terms acknowledgment to registration
  class ::ApplicationController
    def require_terms_acknowledgment
      return unless current_user
      
      acknowledgment = TermsAcknowledgment.find_by(user_id: current_user.id)
      if acknowledgment&.status == 'pending'
        redirect_to '/terms'
        return
      end
    end
  end
  
  # Add to application controller
  ApplicationController.class_eval do
    before_action :check_terms_acknowledgment, if: :current_user
    
    private
    
    def check_terms_acknowledgment
      return if controller_name == 'terms'
      return if controller_name == 'sessions'
      return if controller_name == 'users' && action_name == 'create'
      
      acknowledgment = TermsAcknowledgment.find_by(user_id: current_user.id)
      if acknowledgment&.status == 'pending'
        redirect_to '/terms'
      end
    end
  end
end

# Database migration
class AddTermsAcknowledgmentTable < ActiveRecord::Migration[7.0]
  def up
    create_table :terms_acknowledgments do |t|
      t.integer :user_id, null: false
      t.string :status, default: 'pending'  # 'pending', 'acknowledged', 'declined'
      t.string :terms_version, null: false
      t.datetime :acknowledged_at
      t.text :ip_address
      t.text :user_agent
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    
    add_index :terms_acknowledgments, :user_id, unique: true
    add_index :terms_acknowledgments, :status
    add_index :terms_acknowledgments, :terms_version
    
    # Add custom field to users table
    add_column :users, :terms_acknowledged, :boolean, default: false
    add_column :users, :terms_acknowledged_at, :datetime
  end
  
  def down
    drop_table :terms_acknowledgments
    remove_column :users, :terms_acknowledged
    remove_column :users, :terms_acknowledged_at
  end
  
  private
  
  def current_terms_version
    '1.0.0'  # Update this when terms change
  end
end 