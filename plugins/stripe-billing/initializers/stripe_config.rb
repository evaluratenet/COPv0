# Stripe Configuration
# Sets up Stripe API keys and webhook handling

after_initialize do
  # Configure Stripe API key
  Stripe.api_key = SiteSetting.stripe_secret_key
  
  # Set Stripe API version
  Stripe.api_version = '2023-10-16'
  
  # Configure webhook endpoint
  if SiteSetting.stripe_webhook_secret.present?
    # Webhook endpoint is configured in the billing controller
    Rails.logger.info "Stripe webhook endpoint configured"
  else
    Rails.logger.warn "Stripe webhook secret not configured"
  end
  
  # Add Stripe settings to admin interface
  add_admin_route 'stripe_settings.title', 'stripe_settings'
  
  # Add Stripe settings to site settings
  SiteSetting.class_eval do
    def self.stripe_secret_key
      get('stripe_secret_key')
    end
    
    def self.stripe_publishable_key
      get('stripe_publishable_key')
    end
    
    def self.stripe_webhook_secret
      get('stripe_webhook_secret')
    end
    
    def self.stripe_monthly_price_id
      get('stripe_monthly_price_id')
    end
    
    def self.stripe_annual_price_id
      get('stripe_annual_price_id')
    end
  end
  
  # Schedule billing jobs
  if defined?(Sidekiq)
    # Trial expiration check - daily
    Sidekiq::Cron::Job.create(
      name: 'Trial Expiration Check - daily',
      cron: '0 2 * * *',
      class: 'Jobs::TrialExpiration'
    )
    
    # Subscription reminders - daily
    Sidekiq::Cron::Job.create(
      name: 'Subscription Reminders - daily',
      cron: '0 9 * * *',
      class: 'Jobs::SubscriptionReminder'
    )
    
    # Stripe sync - hourly
    Sidekiq::Cron::Job.create(
      name: 'Stripe Sync - hourly',
      cron: '0 * * * *',
      class: 'Jobs::StripeSync'
    )
  end
  
  # Add billing information to user serializer
  UserSerializer.class_eval do
    attributes :subscription_status, :trial_days_remaining
    
    def subscription_status
      subscription = object.subscriptions.active.first
      return 'none' unless subscription
      
      if subscription.is_trial?
        'trial'
      elsif subscription.is_active?
        'active'
      elsif subscription.is_past_due?
        'past_due'
      elsif subscription.is_canceled?
        'canceled'
      else
        'inactive'
      end
    end
    
    def trial_days_remaining
      subscription = object.subscriptions.active.first
      subscription&.trial_days_remaining || 0
    end
  end
  
  # Add billing information to current user serializer
  CurrentUserSerializer.class_eval do
    attributes :subscription, :billing_url
    
    def subscription
      subscription = object.subscriptions.active.first
      return nil unless subscription
      
      {
        id: subscription.id,
        status: subscription.status,
        plan_type: subscription.plan_type,
        plan_display_name: subscription.plan_display_name,
        is_trial: subscription.is_trial?,
        trial_days_remaining: subscription.trial_days_remaining,
        next_billing_date: subscription.next_billing_date,
        amount: subscription.amount_in_dollars
      }
    end
    
    def billing_url
      "#{Discourse.base_url}/billing"
    end
  end
end 