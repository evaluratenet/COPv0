module Jobs
  class PaymentFailed < ::Jobs::Base
    sidekiq_options retry: 3
    
    def execute(args)
      user_id = args[:user_id]
      subscription_id = args[:subscription_id]
      invoice_id = args[:invoice_id]
      
      user = User.find(user_id)
      subscription = Subscription.find(subscription_id)
      
      # Send payment failed notification
      send_payment_failed_notification(user, subscription, invoice_id)
      
      # Log the failed payment event
      BillingEvent.log_manual_event(subscription, 'payment_failed_notification', {
        invoice_id: invoice_id,
        user_id: user_id,
        sent_at: Time.current
      })
      
      # Check if this is a recurring failure
      check_recurring_failures(subscription)
    end
    
    private
    
    def send_payment_failed_notification(user, subscription, invoice_id)
      # Get invoice details from Stripe
      invoice_details = get_invoice_details(invoice_id)
      
      email_opts = {
        to: user.email,
        subject: I18n.t('billing.payment_failed.subject'),
        template: 'payment_failed_notification',
        template_vars: {
          username: user.username,
          peer_id: user.custom_fields['peer_id'],
          plan_name: subscription.plan_display_name,
          amount: subscription.amount_in_dollars,
          invoice_id: invoice_id,
          failure_reason: invoice_details[:failure_reason],
          next_retry_date: invoice_details[:next_retry_date],
          billing_url: "#{Discourse.base_url}/billing",
          payment_method_url: "#{Discourse.base_url}/billing/payment_method",
          support_url: "#{Discourse.base_url}/contact"
        }
      }
      
      Email::Sender.new(Email::Message.new(email_opts), :payment_failed).send
    end
    
    def get_invoice_details(invoice_id)
      Stripe.api_key = SiteSetting.stripe_secret_key
      
      begin
        invoice = Stripe::Invoice.retrieve(invoice_id)
        
        {
          failure_reason: invoice.last_finalization_error&.message || 'Payment method declined',
          next_retry_date: invoice.next_payment_attempt ? Time.at(invoice.next_payment_attempt) : nil,
          attempts_remaining: invoice.attempt_count || 0
        }
      rescue => e
        Rails.logger.error "Failed to retrieve invoice #{invoice_id}: #{e.message}"
        
        {
          failure_reason: 'Payment method declined',
          next_retry_date: nil,
          attempts_remaining: 0
        }
      end
    end
    
    def check_recurring_failures(subscription)
      # Count failed payments in the last 30 days
      failed_payments = BillingEvent.where(subscription_id: subscription.id)
                                   .where(event_type: ['payment_failed', 'invoice_payment_failed'])
                                   .where('created_at > ?', 30.days.ago)
                                   .count
      
      if failed_payments >= 3
        # Send escalation notification
        send_escalation_notification(subscription.user, subscription, failed_payments)
        
        # Log escalation
        BillingEvent.log_manual_event(subscription, 'payment_escalation', {
          failed_payments_count: failed_payments,
          escalated_at: Time.current
        })
      end
    end
    
    def send_escalation_notification(user, subscription, failed_payments_count)
      email_opts = {
        to: user.email,
        subject: I18n.t('billing.payment_escalation.subject'),
        template: 'payment_escalation',
        template_vars: {
          username: user.username,
          peer_id: user.custom_fields['peer_id'],
          plan_name: subscription.plan_display_name,
          failed_payments_count: failed_payments_count,
          billing_url: "#{Discourse.base_url}/billing",
          support_url: "#{Discourse.base_url}/contact"
        }
      }
      
      Email::Sender.new(Email::Message.new(email_opts), :payment_failed).send
    end
  end
end 