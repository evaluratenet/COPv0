class Admin::BillingController < Admin::AdminController
  def index
    @subscriptions = Subscription.includes(:user, :payment_methods, :billing_events)
                                .order(created_at: :desc)
                                .page(params[:page])
    
    @statistics = Subscription.billing_statistics
    
    respond_to do |format|
      format.html
      format.json { render json: @subscriptions }
    end
  end
  
  def show
    @subscription = Subscription.includes(:user, :payment_methods, :billing_events)
                               .find(params[:id])
    
    @billing_events = @subscription.billing_events.order(created_at: :desc).limit(50)
    @payment_methods = @subscription.payment_methods
    
    respond_to do |format|
      format.html
      format.json { render json: subscription_data(@subscription) }
    end
  end
  
  def subscriptions
    @subscriptions = Subscription.includes(:user)
                                .order(created_at: :desc)
                                .page(params[:page])
    
    # Filter by status
    if params[:status].present?
      @subscriptions = @subscriptions.where(status: params[:status])
    end
    
    # Filter by plan type
    if params[:plan_type].present?
      @subscriptions = @subscriptions.where(plan_type: params[:plan_type])
    end
    
    # Filter by trial status
    if params[:trial] == 'true'
      @subscriptions = @subscriptions.trial
    elsif params[:trial] == 'false'
      @subscriptions = @subscriptions.where.not(status: 'trialing')
    end
    
    render json: {
      subscriptions: @subscriptions.map { |s| subscription_data(s) },
      pagination: {
        current_page: @subscriptions.current_page,
        total_pages: @subscriptions.total_pages,
        total_count: @subscriptions.total_count
      }
    }
  end
  
  def payments
    @billing_events = BillingEvent.includes(:subscription => :user)
                                  .where(event_type: ['payment_succeeded', 'payment_failed', 'invoice_payment_succeeded', 'invoice_payment_failed'])
                                  .order(created_at: :desc)
                                  .page(params[:page])
    
    render json: {
      events: @billing_events.map { |e| billing_event_data(e) },
      pagination: {
        current_page: @billing_events.current_page,
        total_pages: @billing_events.total_pages,
        total_count: @billing_events.total_count
      }
    }
  end
  
  def statistics
    @statistics = Subscription.billing_statistics
    
    # Additional statistics
    @statistics.merge!({
      revenue_this_month: calculate_monthly_revenue,
      revenue_this_year: calculate_yearly_revenue,
      average_subscription_value: calculate_average_subscription_value,
      churn_rate: calculate_churn_rate,
      trial_conversion_rate: calculate_trial_conversion_rate
    })
    
    render json: @statistics
  end
  
  def sync_stripe
    begin
      Subscription.sync_with_stripe
      
      render json: {
        success: true,
        message: 'Successfully synced subscriptions with Stripe'
      }
    rescue => e
      Rails.logger.error "Stripe sync failed: #{e.message}"
      render json: {
        success: false,
        message: 'Failed to sync with Stripe'
      }, status: 500
    end
  end
  
  private
  
  def subscription_data(subscription)
    {
      id: subscription.id,
      user: {
        id: subscription.user.id,
        username: subscription.user.username,
        email: subscription.user.email,
        peer_id: subscription.user.custom_fields['peer_id']
      },
      stripe_subscription_id: subscription.stripe_subscription_id,
      stripe_customer_id: subscription.stripe_customer_id,
      status: subscription.status,
      plan_type: subscription.plan_type,
      plan_display_name: subscription.plan_display_name,
      amount: subscription.amount_in_dollars,
      currency: subscription.currency,
      current_period_start: subscription.current_period_start,
      current_period_end: subscription.current_period_end,
      trial_start: subscription.trial_start,
      trial_end: subscription.trial_end,
      is_trial: subscription.is_trial?,
      trial_days_remaining: subscription.trial_days_remaining,
      is_active: subscription.is_active?,
      is_past_due: subscription.is_past_due?,
      is_canceled: subscription.is_canceled?,
      canceled_at: subscription.canceled_at,
      next_billing_date: subscription.next_billing_date,
      created_at: subscription.created_at,
      updated_at: subscription.updated_at,
      payment_methods_count: subscription.payment_methods.count,
      billing_events_count: subscription.billing_events.count
    }
  end
  
  def billing_event_data(event)
    {
      id: event.id,
      event_type: event.event_type,
      event_display_name: event.event_display_name,
      event_description: event.event_description,
      stripe_event_id: event.stripe_event_id,
      success: event.success,
      amount: event.amount_in_dollars,
      currency: event.currency,
      created_at: event.created_at,
      subscription: {
        id: event.subscription.id,
        user: {
          username: event.subscription.user.username,
          peer_id: event.subscription.user.custom_fields['peer_id']
        }
      }
    }
  end
  
  def calculate_monthly_revenue
    Subscription.active
                .where('current_period_start >= ?', 1.month.ago)
                .sum(:amount) / 100.0
  end
  
  def calculate_yearly_revenue
    Subscription.active
                .where('current_period_start >= ?', 1.year.ago)
                .sum(:amount) / 100.0
  end
  
  def calculate_average_subscription_value
    active_subs = Subscription.active
    return 0 if active_subs.count == 0
    
    active_subs.sum(:amount) / 100.0 / active_subs.count
  end
  
  def calculate_churn_rate
    total_subs = Subscription.count
    return 0 if total_subs == 0
    
    canceled_subs = Subscription.canceled.where('canceled_at >= ?', 1.month.ago).count
    (canceled_subs.to_f / total_subs * 100).round(2)
  end
  
  def calculate_trial_conversion_rate
    trial_subs = Subscription.trial.count
    return 0 if trial_subs == 0
    
    converted_subs = Subscription.where(status: 'active').where('trial_end < ?', Time.current).count
    (converted_subs.to_f / trial_subs * 100).round(2)
  end
end 