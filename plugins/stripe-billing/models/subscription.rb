class Subscription < ActiveRecord::Base
  belongs_to :user
  has_many :billing_events, dependent: :destroy
  has_one :payment_method, dependent: :destroy
  
  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :user_id, presence: true
  validates :status, presence: true, inclusion: { in: %w[trialing active past_due canceled unpaid incomplete] }
  validates :plan_type, presence: true, inclusion: { in: %w[monthly annual] }
  
  scope :active, -> { where(status: ['trialing', 'active']) }
  scope :trial, -> { where(status: 'trialing') }
  scope :expired, -> { where('trial_end < ?', Time.current) }
  scope :past_due, -> { where(status: 'past_due') }
  scope :canceled, -> { where(status: 'canceled') }
  scope :by_plan, ->(plan) { where(plan_type: plan) }
  
  before_create :set_trial_period
  before_save :update_status_timestamp
  
  TRIAL_DAYS = 30
  MONTHLY_PRICE = 5000 # $50.00 in cents
  ANNUAL_PRICE = 50000 # $500.00 in cents
  
  def self.create_subscription(user, plan_type, stripe_token)
    # Cancel any existing subscriptions
    user.subscriptions.active.update_all(
      status: 'canceled',
      canceled_at: Time.current
    )
    
    # Create Stripe subscription
    stripe_subscription = create_stripe_subscription(user, plan_type, stripe_token)
    
    # Create local subscription record
    create!(
      user_id: user.id,
      stripe_subscription_id: stripe_subscription.id,
      stripe_customer_id: stripe_subscription.customer,
      plan_type: plan_type,
      status: stripe_subscription.status,
      current_period_start: Time.at(stripe_subscription.current_period_start),
      current_period_end: Time.at(stripe_subscription.current_period_end),
      trial_start: stripe_subscription.trial_start ? Time.at(stripe_subscription.trial_start) : nil,
      trial_end: stripe_subscription.trial_end ? Time.at(stripe_subscription.trial_end) : nil,
      amount: stripe_subscription.items.data.first.price.unit_amount,
      currency: stripe_subscription.currency
    )
  end
  
  def self.create_stripe_subscription(user, plan_type, stripe_token)
    Stripe.api_key = SiteSetting.stripe_secret_key
    
    # Create or get customer
    customer = find_or_create_stripe_customer(user, stripe_token)
    
    # Get price ID based on plan
    price_id = get_price_id(plan_type)
    
    # Create subscription with trial
    Stripe::Subscription.create(
      customer: customer.id,
      items: [{ price: price_id }],
      trial_period_days: TRIAL_DAYS,
      payment_behavior: 'default_incomplete',
      payment_settings: { save_default_payment_method: 'on_subscription' },
      expand: ['latest_invoice.payment_intent']
    )
  end
  
  def self.find_or_create_stripe_customer(user, stripe_token)
    # Check if user already has a customer
    existing_subscription = user.subscriptions.order(created_at: :desc).first
    
    if existing_subscription&.stripe_customer_id
      customer = Stripe::Customer.retrieve(existing_subscription.stripe_customer_id)
      
      # Update payment method if provided
      if stripe_token
        customer.source = stripe_token
        customer.save
      end
      
      return customer
    end
    
    # Create new customer
    Stripe::Customer.create(
      email: user.email,
      source: stripe_token,
      metadata: {
        user_id: user.id,
        username: user.username,
        peer_id: user.custom_fields['peer_id']
      }
    )
  end
  
  def self.get_price_id(plan_type)
    case plan_type
    when 'monthly'
      SiteSetting.stripe_monthly_price_id
    when 'annual'
      SiteSetting.stripe_annual_price_id
    else
      raise ArgumentError, "Invalid plan type: #{plan_type}"
    end
  end
  
  def self.billing_statistics
    {
      total_subscriptions: count,
      active_subscriptions: active.count,
      trial_subscriptions: trial.count,
      expired_trials: expired.count,
      past_due: past_due.count,
      canceled: canceled.count,
      monthly_revenue: active.by_plan('monthly').sum(:amount),
      annual_revenue: active.by_plan('annual').sum(:amount),
      total_revenue: active.sum(:amount)
    }
  end
  
  def self.sync_with_stripe
    Stripe.api_key = SiteSetting.stripe_secret_key
    
    Subscription.active.find_each do |subscription|
      begin
        stripe_sub = Stripe::Subscription.retrieve(subscription.stripe_subscription_id)
        subscription.update_from_stripe(stripe_sub)
      rescue Stripe::InvalidRequestError => e
        Rails.logger.error "Failed to sync subscription #{subscription.id}: #{e.message}"
      end
    end
  end
  
  def update_from_stripe(stripe_subscription)
    update!(
      status: stripe_subscription.status,
      current_period_start: Time.at(stripe_subscription.current_period_start),
      current_period_end: Time.at(stripe_subscription.current_period_end),
      trial_start: stripe_subscription.trial_start ? Time.at(stripe_subscription.trial_start) : nil,
      trial_end: stripe_subscription.trial_end ? Time.at(stripe_subscription.trial_end) : nil,
      canceled_at: stripe_subscription.canceled_at ? Time.at(stripe_subscription.canceled_at) : nil
    )
  end
  
  def cancel_subscription
    Stripe.api_key = SiteSetting.stripe_secret_key
    
    stripe_subscription = Stripe::Subscription.retrieve(stripe_subscription_id)
    stripe_subscription.cancel_at_period_end = true
    stripe_subscription.save
    
    update!(
      status: 'canceled',
      canceled_at: Time.current
    )
    
    # Log the cancellation
    billing_events.create!(
      event_type: 'subscription_canceled',
      stripe_event_id: "manual_cancel_#{id}",
      metadata: {
        canceled_at: Time.current,
        canceled_by: 'user'
      }
    )
  end
  
  def reactivate_subscription
    Stripe.api_key = SiteSetting.stripe_secret_key
    
    stripe_subscription = Stripe::Subscription.retrieve(stripe_subscription_id)
    stripe_subscription.cancel_at_period_end = false
    stripe_subscription.save
    
    update!(status: 'active')
    
    # Log the reactivation
    billing_events.create!(
      event_type: 'subscription_reactivated',
      stripe_event_id: "manual_reactivate_#{id}",
      metadata: {
        reactivated_at: Time.current,
        reactivated_by: 'user'
      }
    )
  end
  
  def is_trial?
    status == 'trialing' && trial_end && trial_end > Time.current
  end
  
  def trial_days_remaining
    return 0 unless is_trial?
    ((trial_end - Time.current) / 1.day).ceil
  end
  
  def is_active?
    ['trialing', 'active'].include?(status)
  end
  
  def is_past_due?
    status == 'past_due'
  end
  
  def is_canceled?
    status == 'canceled'
  end
  
  def next_billing_date
    current_period_end
  end
  
  def amount_in_dollars
    amount / 100.0
  end
  
  def plan_display_name
    case plan_type
    when 'monthly'
      'Monthly Plan ($50/month)'
    when 'annual'
      'Annual Plan ($500/year)'
    else
      'Unknown Plan'
    end
  end
  
  private
  
  def set_trial_period
    self.trial_start = Time.current
    self.trial_end = TRIAL_DAYS.days.from_now
  end
  
  def update_status_timestamp
    if status_changed?
      case status
      when 'canceled'
        self.canceled_at = Time.current
      when 'active'
        self.activated_at = Time.current
      end
    end
  end
end 