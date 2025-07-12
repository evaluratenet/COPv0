class BillingEvent < ActiveRecord::Base
  belongs_to :subscription
  
  validates :event_type, presence: true
  validates :stripe_event_id, presence: true, uniqueness: true
  validates :subscription_id, presence: true
  
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }
  
  EVENT_TYPES = %w[
    subscription_created
    subscription_updated
    subscription_canceled
    subscription_reactivated
    payment_succeeded
    payment_failed
    invoice_payment_succeeded
    invoice_payment_failed
    trial_ended
    payment_method_attached
    payment_method_detached
    customer_updated
  ]
  
  def self.create_from_stripe_event(stripe_event)
    event_type = stripe_event.type.gsub('.', '_')
    
    # Find subscription based on event data
    subscription = find_subscription_from_event(stripe_event)
    return unless subscription
    
    create!(
      subscription_id: subscription.id,
      event_type: event_type,
      stripe_event_id: stripe_event.id,
      success: true,
      metadata: {
        stripe_event_type: stripe_event.type,
        stripe_event_created: Time.at(stripe_event.created),
        event_data: stripe_event.data.object.to_h
      }
    )
  end
  
  def self.find_subscription_from_event(stripe_event)
    case stripe_event.type
    when 'customer.subscription.created',
         'customer.subscription.updated',
         'customer.subscription.deleted'
      subscription_id = stripe_event.data.object.id
      Subscription.find_by(stripe_subscription_id: subscription_id)
      
    when 'invoice.payment_succeeded',
         'invoice.payment_failed'
      subscription_id = stripe_event.data.object.subscription
      Subscription.find_by(stripe_subscription_id: subscription_id)
      
    when 'payment_method.attached',
         'payment_method.detached'
      customer_id = stripe_event.data.object.customer
      Subscription.find_by(stripe_customer_id: customer_id)
      
    when 'customer.updated'
      customer_id = stripe_event.data.object.id
      Subscription.find_by(stripe_customer_id: customer_id)
      
    else
      nil
    end
  end
  
  def self.log_manual_event(subscription, event_type, metadata = {})
    create!(
      subscription_id: subscription.id,
      event_type: event_type,
      stripe_event_id: "manual_#{event_type}_#{subscription.id}_#{Time.current.to_i}",
      success: true,
      metadata: metadata.merge(
        manual_event: true,
        created_at: Time.current
      )
    )
  end
  
  def self.payment_events_count(subscription_id, time_period = 30.days)
    where(subscription_id: subscription_id)
      .where(event_type: ['payment_succeeded', 'payment_failed'])
      .where('created_at > ?', time_period.ago)
      .count
  end
  
  def self.failed_payments_count(subscription_id, time_period = 30.days)
    where(subscription_id: subscription_id)
      .where(event_type: 'payment_failed')
      .where('created_at > ?', time_period.ago)
      .count
  end
  
  def is_payment_event?
    ['payment_succeeded', 'payment_failed', 'invoice_payment_succeeded', 'invoice_payment_failed'].include?(event_type)
  end
  
  def is_subscription_event?
    ['subscription_created', 'subscription_updated', 'subscription_canceled', 'subscription_reactivated'].include?(event_type)
  end
  
  def is_trial_event?
    ['trial_ended'].include?(event_type)
  end
  
  def event_display_name
    event_type.humanize.titleize
  end
  
  def event_description
    case event_type
    when 'subscription_created'
      'Subscription created successfully'
    when 'subscription_updated'
      'Subscription details updated'
    when 'subscription_canceled'
      'Subscription canceled'
    when 'subscription_reactivated'
      'Subscription reactivated'
    when 'payment_succeeded'
      'Payment processed successfully'
    when 'payment_failed'
      'Payment failed'
    when 'invoice_payment_succeeded'
      'Invoice payment successful'
    when 'invoice_payment_failed'
      'Invoice payment failed'
    when 'trial_ended'
      'Trial period ended'
    when 'payment_method_attached'
      'Payment method added'
    when 'payment_method_detached'
      'Payment method removed'
    when 'customer_updated'
      'Customer information updated'
    else
      'Unknown event'
    end
  end
  
  def amount_in_dollars
    return nil unless metadata['event_data']&.dig('amount')
    metadata['event_data']['amount'] / 100.0
  end
  
  def currency
    metadata['event_data']&.dig('currency') || 'usd'
  end
  
  def stripe_event_created
    return nil unless metadata['stripe_event_created']
    Time.at(metadata['stripe_event_created'])
  end
end 