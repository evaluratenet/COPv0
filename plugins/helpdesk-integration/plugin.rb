# name: helpdesk-integration
# about: Integrates HelpdeskZ helpdesk and knowledge base system with Circle of Peers
# version: 1.0.0
# authors: Circle of Peers Team
# url: https://github.com/circleofpeers/discourse-helpdesk-integration

register_asset 'stylesheets/helpdesk-integration.scss'

enabled_site_setting :helpdesk_integration_enabled

after_initialize do
  # Load the plugin's models and controllers
  load File.expand_path('../models/support_ticket.rb', __FILE__)
  load File.expand_path('../models/knowledge_article.rb', __FILE__)
  load File.expand_path('../controllers/helpdesk_controller.rb', __FILE__)
  load File.expand_path('../jobs/create_helpdesk_ticket.rb', __FILE__)
  load File.expand_path('../jobs/sync_helpdesk_data.rb', __FILE__)
  
  # Add routes
  Discourse::Application.routes.append do
    get '/support' => 'helpdesk#index'
    get '/support/tickets' => 'helpdesk#tickets'
    get '/support/tickets/new' => 'helpdesk#new_ticket'
    post '/support/tickets' => 'helpdesk#create_ticket'
    get '/support/tickets/:id' => 'helpdesk#show_ticket'
    get '/support/kb' => 'helpdesk#knowledge_base'
    get '/support/kb/:id' => 'helpdesk#show_article'
    get '/admin/helpdesk' => 'helpdesk#admin_dashboard'
    get '/admin/helpdesk/tickets' => 'helpdesk#admin_tickets'
    get '/admin/helpdesk/kb' => 'helpdesk#admin_kb'
  end
  
  # Add admin panel
  add_admin_route 'helpdesk.title', 'helpdesk'
  
  # Hook into user registration for welcome support
  on(:user_approved) do |user|
    Jobs.enqueue(:create_welcome_support_ticket, user_id: user.id)
  end
  
  # Hook into billing issues for automatic ticket creation
  on(:subscription_payment_failed) do |subscription|
    Jobs.enqueue(:create_billing_support_ticket, subscription_id: subscription.id)
  end
  
  # Hook into content moderation for support tickets
  on(:post_flagged) do |flag|
    if flag.violation_type.severity >= 4
      Jobs.enqueue(:create_moderation_support_ticket, flag_id: flag.id)
    end
  end
  
  # Add to user serializer
  add_to_serializer(:user, :support_tickets_count) do
    SupportTicket.where(user_id: object.id).count
  end
  
  # Add to user serializer
  add_to_serializer(:user, :open_support_tickets) do
    SupportTicket.where(user_id: object.id, status: 'open').count
  end
  
  # Override support pages
  module ::HelpdeskIntegration
    class Engine < ::Rails::Engine
      engine_name "helpdesk_integration"
      isolate_namespace HelpdeskIntegration
    end
  end
  
  # Add to application controller
  ApplicationController.class_eval do
    before_action :check_support_access, if: :current_user
    
    private
    
    def check_support_access
      return if controller_name == 'helpdesk'
      return if controller_name == 'sessions'
      
      # Check if user has active subscription for support access
      if current_user && !current_user.admin?
        subscription = current_user.subscriptions.active.first
        unless subscription&.is_active? || subscription&.is_trial?
          # Redirect to billing if no active subscription
          redirect_to '/billing' if request.path.start_with?('/support')
        end
      end
    end
  end
end

# Database migration
class CreateSupportTickets < ActiveRecord::Migration[7.0]
  def change
    create_table :support_tickets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ticket_number, null: false, unique: true
      t.string :subject, null: false
      t.text :description
      t.string :category, default: 'general'
      t.string :priority, default: 'medium'
      t.string :status, default: 'open'
      t.string :helpdeskz_ticket_id
      t.json :metadata
      t.references :assigned_to, null: true, foreign_key: { to_table: :users }
      t.datetime :resolved_at
      t.timestamps
    end
    
    add_index :support_tickets, :ticket_number, unique: true
    add_index :support_tickets, :status
    add_index :support_tickets, :category
    add_index :support_tickets, :helpdeskz_ticket_id
  end
end

class CreateKnowledgeArticles < ActiveRecord::Migration[7.0]
  def change
    create_table :knowledge_articles do |t|
      t.string :title, null: false
      t.text :content
      t.string :category
      t.string :tags, array: true, default: []
      t.string :helpdeskz_article_id
      t.boolean :published, default: true
      t.integer :view_count, default: 0
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    
    add_index :knowledge_articles, :category
    add_index :knowledge_articles, :tags, using: 'gin'
    add_index :knowledge_articles, :helpdeskz_article_id
    add_index :knowledge_articles, :published
  end
end 