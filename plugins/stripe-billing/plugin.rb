# name: stripe-billing
# about: Stripe subscription management for Circle of Peers platform
# version: 1.0.0
# authors: Circle of Peers Team
# contact_emails: admin@circleofpeers.com
# url: https://github.com/circle-of-peers/stripe-billing
# required_version: 2.7.0

register_asset 'stylesheets/stripe-billing.scss'
register_asset 'javascripts/stripe-billing.js'

enabled_site_setting :stripe_billing_enabled

after_initialize do
  # Load models
  require_relative 'models/subscription.rb'
  require_relative 'models/payment_method.rb'
  require_relative 'models/billing_event.rb'
  
  # Load controllers
  require_relative 'controllers/billing_controller.rb'
  require_relative 'controllers/admin/billing_controller.rb'
  
  # Load jobs
  require_relative 'jobs/subscription_reminder.rb'
  require_relative 'jobs/trial_expiration.rb'
  require_relative 'jobs/payment_failed.rb'
  
  # Load initializers
  require_relative 'initializers/stripe_config.rb'
  require_relative 'initializers/billing_hooks.rb'
  require_relative 'initializers/admin_interface.rb'
  
  # Register admin routes
  Discourse::Application.routes.append do
    namespace :admin, constraints: StaffConstraint.new do
      resources :billing, only: [:index, :show] do
        collection do
          get :subscriptions
          get :payments
          get :statistics
          post :sync_stripe
        end
      end
    end
  end
  
  # Register user routes
  Discourse::Application.routes.append do
    get '/billing' => 'billing#index'
    get '/billing/subscription' => 'billing#subscription'
    post '/billing/create_subscription' => 'billing#create_subscription'
    post '/billing/cancel_subscription' => 'billing#cancel_subscription'
    post '/billing/update_payment_method' => 'billing#update_payment_method'
    get '/billing/invoices' => 'billing#invoices'
    post '/billing/webhook' => 'billing#webhook'
  end
  
  # Add admin menu item
  add_admin_route 'billing.title', 'billing'
  
  # Add to admin menu
  Admin::DashboardController.class_eval do
    def billing
      @subscriptions = Subscription.includes(:user).order(created_at: :desc)
      @statistics = Subscription.billing_statistics
      
      respond_to do |format|
        format.html
        format.json { render json: @subscriptions }
      end
    end
  end
end 