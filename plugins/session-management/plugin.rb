# name: session-management
# about: Enforces single-session login for Circle of Peers platform
# version: 1.0.0
# authors: Circle of Peers Team
# contact_emails: admin@circleofpeers.com
# url: https://github.com/circle-of-peers/session-management
# required_version: 2.7.0

register_asset 'stylesheets/session-management.scss'
register_asset 'javascripts/session-management.js'

enabled_site_setting :session_management_enabled

after_initialize do
  # Load models
  require_relative 'models/user_session.rb'
  require_relative 'models/session_log.rb'
  
  # Load controllers
  require_relative 'controllers/session_controller.rb'
  require_relative 'controllers/admin/sessions_controller.rb'
  
  # Load jobs
  require_relative 'jobs/session_cleanup.rb'
  require_relative 'jobs/session_notification.rb'
  
  # Load initializers
  require_relative 'initializers/session_hooks.rb'
  require_relative 'initializers/admin_interface.rb'
  
  # Register admin routes
  Discourse::Application.routes.append do
    namespace :admin, constraints: StaffConstraint.new do
      resources :sessions, only: [:index, :show, :destroy] do
        member do
          post :force_logout
        end
        collection do
          post :bulk_force_logout
          get :statistics
        end
      end
    end
  end
  
  # Register user routes
  Discourse::Application.routes.append do
    get '/session/status' => 'session#status'
    post '/session/force_logout_others' => 'session#force_logout_others'
  end
  
  # Add admin menu item
  add_admin_route 'session_management.title', 'sessions'
  
  # Add to admin menu
  Admin::DashboardController.class_eval do
    def sessions
      render_serialized(UserSession.active_sessions, UserSessionSerializer)
    end
  end
end 