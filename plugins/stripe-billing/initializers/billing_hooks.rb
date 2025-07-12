# Billing Hooks
# Integrates billing with user registration and access control

after_initialize do
  # Hook into user registration to create trial subscription
  on(:user_created) do |user|
    # Create trial subscription for new users
    create_trial_subscription(user)
  end
  
  # Hook into user approval to ensure billing access
  on(:user_approved) do |user|
    # Ensure user has active subscription or trial
    ensure_billing_access(user)
  end
  
  # Hook into access control to check subscription status
  on(:check_access) do |user, action|
    # Check if user has active subscription for premium features
    check_subscription_access(user, action)
  end
  
  # Hook into user login to check subscription status
  on(:user_logged_in) do |user, session_id, request|
    # Check subscription status on login
    check_subscription_on_login(user)
  end
  
  # Add billing middleware to check subscription status
  Rails.application.config.middleware.use do |env|
    request = Rack::Request.new(env)
    
    # Skip billing checks for certain paths
    skip_paths = ['/billing/webhook', '/admin', '/assets', '/uploads']
    next unless skip_paths.none? { |path| request.path.start_with?(path) }
    
    # Check if user is logged in
    user_id = env['rack.session']&.dig('user_id')
    next unless user_id
    
    user = User.find_by(id: user_id)
    next unless user
    
    # Check subscription status
    subscription = user.subscriptions.active.first
    
    if subscription&.is_trial?
      # Trial is active, allow access
      next
    elsif subscription&.is_active?
      # Active subscription, allow access
      next
    elsif subscription&.is_past_due?
      # Past due, show billing warning
      env['billing.status'] = 'past_due'
      next
    else
      # No active subscription, redirect to billing
      env['billing.status'] = 'no_subscription'
      next
    end
  end
  
  private
  
  def create_trial_subscription(user)
    # Only create trial if user doesn't already have one
    return if user.subscriptions.any?
    
    # Create trial subscription without payment method
    subscription = Subscription.create!(
      user_id: user.id,
      stripe_subscription_id: "trial_#{user.id}_#{Time.current.to_i}",
      stripe_customer_id: "trial_customer_#{user.id}",
      plan_type: 'monthly', # Default to monthly plan
      status: 'trialing',
      current_period_start: Time.current,
      current_period_end: 30.days.from_now,
      trial_start: Time.current,
      trial_end: 30.days.from_now,
      amount: Subscription::MONTHLY_PRICE,
      currency: 'usd'
    )
    
    # Log trial creation
    BillingEvent.log_manual_event(subscription, 'trial_created', {
      user_id: user.id,
      created_at: Time.current
    })
    
    # Send welcome email with trial information
    Jobs.enqueue(:subscription_reminder, 
      subscription_id: subscription.id,
      reminder_type: 'trial_created'
    )
  end
  
  def ensure_billing_access(user)
    # Ensure user has active subscription or trial
    subscription = user.subscriptions.active.first
    
    unless subscription
      create_trial_subscription(user)
    end
  end
  
  def check_subscription_access(user, action)
    # Define premium features that require active subscription
    premium_features = [
      'create_topic',
      'reply_to_topic',
      'send_private_message',
      'upload_attachment'
    ]
    
    return true unless premium_features.include?(action)
    
    subscription = user.subscriptions.active.first
    return false unless subscription
    
    subscription.is_active? || subscription.is_trial?
  end
  
  def check_subscription_on_login(user)
    subscription = user.subscriptions.active.first
    
    if subscription&.is_trial?
      days_remaining = subscription.trial_days_remaining
      
      # Send trial ending reminder if less than 7 days
      if days_remaining <= 7 && days_remaining > 0
        Jobs.enqueue(:subscription_reminder, 
          subscription_id: subscription.id,
          reminder_type: 'trial_ending'
        )
      end
    elsif subscription&.is_past_due?
      # Send payment reminder
      Jobs.enqueue(:subscription_reminder, 
        subscription_id: subscription.id,
        reminder_type: 'payment_reminder'
      )
    end
  end
end 