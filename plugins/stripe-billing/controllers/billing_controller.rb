class BillingController < ApplicationController
  before_action :ensure_logged_in
  before_action :load_subscription, except: [:index, :create_subscription]
  
  def index
    @subscription = current_user.subscriptions.active.first
    @payment_methods = @subscription&.payment_methods || []
    @billing_events = @subscription&.billing_events&.recent&.order(created_at: :desc)&.limit(10) || []
    
    respond_to do |format|
      format.html
      format.json { render json: { subscription: @subscription, payment_methods: @payment_methods } }
    end
  end
  
  def subscription
    @subscription = current_user.subscriptions.active.first
    
    if @subscription
      render json: {
        subscription: subscription_data(@subscription),
        trial_days_remaining: @subscription.trial_days_remaining,
        next_billing_date: @subscription.next_billing_date,
        is_trial: @subscription.is_trial?
      }
    else
      render json: { subscription: nil }
    end
  end
  
  def create_subscription
    plan_type = params[:plan_type]
    stripe_token = params[:stripe_token]
    
    unless ['monthly', 'annual'].include?(plan_type)
      render json: { success: false, message: 'Invalid plan type' }, status: 400
      return
    end
    
    unless stripe_token
      render json: { success: false, message: 'Payment method required' }, status: 400
      return
    end
    
    begin
      subscription = Subscription.create_subscription(current_user, plan_type, stripe_token)
      
      # Log the subscription creation
      BillingEvent.log_manual_event(subscription, 'subscription_created', {
        plan_type: plan_type,
        created_by: 'user'
      })
      
      render json: {
        success: true,
        message: 'Subscription created successfully',
        subscription: subscription_data(subscription)
      }
    rescue Stripe::CardError => e
      render json: { success: false, message: e.message }, status: 400
    rescue => e
      Rails.logger.error "Subscription creation failed: #{e.message}"
      render json: { success: false, message: 'Failed to create subscription. Please try again.' }, status: 500
    end
  end
  
  def cancel_subscription
    begin
      @subscription.cancel_subscription
      
      render json: {
        success: true,
        message: 'Subscription canceled successfully. You will continue to have access until the end of your current billing period.'
      }
    rescue => e
      Rails.logger.error "Subscription cancellation failed: #{e.message}"
      render json: { success: false, message: 'Failed to cancel subscription. Please try again.' }, status: 500
    end
  end
  
  def reactivate_subscription
    begin
      @subscription.reactivate_subscription
      
      render json: {
        success: true,
        message: 'Subscription reactivated successfully'
      }
    rescue => e
      Rails.logger.error "Subscription reactivation failed: #{e.message}"
      render json: { success: false, message: 'Failed to reactivate subscription. Please try again.' }, status: 500
    end
  end
  
  def update_payment_method
    stripe_token = params[:stripe_token]
    
    unless stripe_token
      render json: { success: false, message: 'Payment method required' }, status: 400
      return
    end
    
    begin
      Stripe.api_key = SiteSetting.stripe_secret_key
      
      # Create new payment method
      payment_method = Stripe::PaymentMethod.create(
        type: 'card',
        card: { token: stripe_token }
      )
      
      # Attach to customer
      payment_method.attach(customer: @subscription.stripe_customer_id)
      
      # Set as default
      customer = Stripe::Customer.retrieve(@subscription.stripe_customer_id)
      customer.invoice_settings.default_payment_method = payment_method.id
      customer.save
      
      # Create local payment method record
      PaymentMethod.create_from_stripe(payment_method, @subscription)
      
      render json: {
        success: true,
        message: 'Payment method updated successfully'
      }
    rescue Stripe::CardError => e
      render json: { success: false, message: e.message }, status: 400
    rescue => e
      Rails.logger.error "Payment method update failed: #{e.message}"
      render json: { success: false, message: 'Failed to update payment method. Please try again.' }, status: 500
    end
  end
  
  def invoices
    @invoices = []
    
    if @subscription
      Stripe.api_key = SiteSetting.stripe_secret_key
      
      begin
        stripe_invoices = Stripe::Invoice.list(
          customer: @subscription.stripe_customer_id,
          limit: 20
        )
        
        @invoices = stripe_invoices.data.map do |invoice|
          {
            id: invoice.id,
            amount_paid: invoice.amount_paid / 100.0,
            amount_due: invoice.amount_due / 100.0,
            status: invoice.status,
            created: Time.at(invoice.created),
            due_date: invoice.due_date ? Time.at(invoice.due_date) : nil,
            pdf_url: invoice.invoice_pdf,
            hosted_invoice_url: invoice.hosted_invoice_url
          }
        end
      rescue => e
        Rails.logger.error "Failed to fetch invoices: #{e.message}"
      end
    end
    
    render json: { invoices: @invoices }
  end
  
  def webhook
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = SiteSetting.stripe_webhook_secret
    
    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      render json: { error: 'Invalid payload' }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: 'Invalid signature' }, status: 400
      return
    end
    
    # Process the event
    case event.type
    when 'customer.subscription.created',
         'customer.subscription.updated',
         'customer.subscription.deleted'
      handle_subscription_event(event)
    when 'invoice.payment_succeeded',
         'invoice.payment_failed'
      handle_payment_event(event)
    when 'payment_method.attached',
         'payment_method.detached'
      handle_payment_method_event(event)
    when 'customer.updated'
      handle_customer_event(event)
    end
    
    render json: { received: true }
  end
  
  private
  
  def load_subscription
    @subscription = current_user.subscriptions.active.first
    
    unless @subscription
      render json: { success: false, message: 'No active subscription found' }, status: 404
    end
  end
  
  def subscription_data(subscription)
    {
      id: subscription.id,
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
      next_billing_date: subscription.next_billing_date
    }
  end
  
  def handle_subscription_event(event)
    subscription = Subscription.find_by(stripe_subscription_id: event.data.object.id)
    return unless subscription
    
    subscription.update_from_stripe(event.data.object)
    BillingEvent.create_from_stripe_event(event)
  end
  
  def handle_payment_event(event)
    subscription = Subscription.find_by(stripe_subscription_id: event.data.object.subscription)
    return unless subscription
    
    BillingEvent.create_from_stripe_event(event)
    
    # Send notification for failed payments
    if event.type == 'invoice.payment_failed'
      Jobs.enqueue(:payment_failed, 
        user_id: subscription.user_id,
        subscription_id: subscription.id,
        invoice_id: event.data.object.id
      )
    end
  end
  
  def handle_payment_method_event(event)
    customer_id = event.data.object.customer
    subscription = Subscription.find_by(stripe_customer_id: customer_id)
    return unless subscription
    
    BillingEvent.create_from_stripe_event(event)
    
    # Update local payment method records
    if event.type == 'payment_method.attached'
      PaymentMethod.create_from_stripe(event.data.object, subscription)
    elsif event.type == 'payment_method.detached'
      payment_method = PaymentMethod.find_by(stripe_payment_method_id: event.data.object.id)
      payment_method&.destroy
    end
  end
  
  def handle_customer_event(event)
    customer_id = event.data.object.id
    subscription = Subscription.find_by(stripe_customer_id: customer_id)
    return unless subscription
    
    BillingEvent.create_from_stripe_event(event)
  end
end 