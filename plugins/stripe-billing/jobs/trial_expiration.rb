module Jobs
  class TrialExpiration < ::Jobs::Base
    sidekiq_options retry: 3
    
    def execute(args)
      # Find subscriptions with expired trials
      expired_trials = Subscription.trial.where('trial_end < ?', Time.current)
      
      expired_trials.each do |subscription|
        handle_trial_expiration(subscription)
      end
      
      # Find subscriptions expiring soon (3 days)
      expiring_soon = Subscription.trial.where('trial_end BETWEEN ? AND ?', 
                                              Time.current, 
                                              3.days.from_now)
      
      expiring_soon.each do |subscription|
        send_trial_expiring_reminder(subscription)
      end
    end
    
    private
    
    def handle_trial_expiration(subscription)
      user = subscription.user
      
      # Update subscription status
      subscription.update!(status: 'past_due')
      
      # Log the trial expiration
      BillingEvent.log_manual_event(subscription, 'trial_ended', {
        trial_end_date: subscription.trial_end,
        user_id: user.id
      })
      
      # Send trial expiration notification
      send_trial_expired_notification(user, subscription)
      
      # Check if user has payment method
      if subscription.payment_methods.any?
        # Attempt to charge the user
        attempt_payment(subscription)
      else
        # Send payment method required notification
        send_payment_method_required_notification(user, subscription)
      end
    end
    
    def send_trial_expired_notification(user, subscription)
      email_opts = {
        to: user.email,
        subject: I18n.t('billing.trial_expired.subject'),
        template: 'trial_expired',
        template_vars: {
          username: user.username,
          peer_id: user.custom_fields['peer_id'],
          trial_end_date: subscription.trial_end.strftime('%B %d, %Y'),
          plan_name: subscription.plan_display_name,
          billing_url: "#{Discourse.base_url}/billing",
          support_url: "#{Discourse.base_url}/contact"
        }
      }
      
      Email::Sender.new(Email::Message.new(email_opts), :trial_expiration).send
    end
    
    def send_trial_expiring_reminder(subscription)
      user = subscription.user
      days_remaining = subscription.trial_days_remaining
      
      # Only send reminder if not already sent recently
      recent_reminder = BillingEvent.where(subscription_id: subscription.id)
                                   .where(event_type: 'trial_expiring_reminder')
                                   .where('created_at > ?', 1.day.ago)
                                   .exists?
      
      return if recent_reminder
      
      email_opts = {
        to: user.email,
        subject: I18n.t('billing.trial_expiring.subject', days: days_remaining),
        template: 'trial_expiring',
        template_vars: {
          username: user.username,
          peer_id: user.custom_fields['peer_id'],
          days_remaining: days_remaining,
          trial_end_date: subscription.trial_end.strftime('%B %d, %Y'),
          plan_name: subscription.plan_display_name,
          billing_url: "#{Discourse.base_url}/billing",
          support_url: "#{Discourse.base_url}/contact"
        }
      }
      
      Email::Sender.new(Email::Message.new(email_opts), :trial_expiration).send
      
      # Log the reminder
      BillingEvent.log_manual_event(subscription, 'trial_expiring_reminder', {
        days_remaining: days_remaining,
        sent_at: Time.current
      })
    end
    
    def send_payment_method_required_notification(user, subscription)
      email_opts = {
        to: user.email,
        subject: I18n.t('billing.payment_method_required.subject'),
        template: 'payment_method_required',
        template_vars: {
          username: user.username,
          peer_id: user.custom_fields['peer_id'],
          plan_name: subscription.plan_display_name,
          billing_url: "#{Discourse.base_url}/billing",
          support_url: "#{Discourse.base_url}/contact"
        }
      }
      
      Email::Sender.new(Email::Message.new(email_opts), :trial_expiration).send
    end
    
    def attempt_payment(subscription)
      Stripe.api_key = SiteSetting.stripe_secret_key
      
      begin
        # Create invoice for the subscription
        invoice = Stripe::Invoice.create(
          customer: subscription.stripe_customer_id,
          subscription: subscription.stripe_subscription_id,
          auto_advance: true
        )
        
        # Pay the invoice
        invoice.pay
        
        # Update subscription status
        subscription.update!(status: 'active')
        
        # Log successful payment
        BillingEvent.log_manual_event(subscription, 'trial_payment_succeeded', {
          invoice_id: invoice.id,
          amount: invoice.amount_paid,
          paid_at: Time.current
        })
        
        # Send payment success notification
        send_payment_success_notification(subscription.user, subscription)
        
      rescue Stripe::CardError => e
        # Payment failed
        subscription.update!(status: 'past_due')
        
        # Log failed payment
        BillingEvent.log_manual_event(subscription, 'trial_payment_failed', {
          error: e.message,
          failed_at: Time.current
        })
        
        # Send payment failed notification
        send_payment_failed_notification(subscription.user, subscription, e.message)
        
      rescue => e
        Rails.logger.error "Trial payment attempt failed for subscription #{subscription.id}: #{e.message}"
        
        # Log error
        BillingEvent.log_manual_event(subscription, 'trial_payment_error', {
          error: e.message,
          error_at: Time.current
        })
      end
    end
    
    def send_payment_success_notification(user, subscription)
      email_opts = {
        to: user.email,
        subject: I18n.t('billing.payment_success.subject'),
        template: 'payment_success',
        template_vars: {
          username: user.username,
          peer_id: user.custom_fields['peer_id'],
          plan_name: subscription.plan_display_name,
          amount: subscription.amount_in_dollars,
          billing_url: "#{Discourse.base_url}/billing"
        }
      }
      
      Email::Sender.new(Email::Message.new(email_opts), :trial_expiration).send
    end
    
    def send_payment_failed_notification(user, subscription, error_message)
      email_opts = {
        to: user.email,
        subject: I18n.t('billing.payment_failed.subject'),
        template: 'payment_failed',
        template_vars: {
          username: user.username,
          peer_id: user.custom_fields['peer_id'],
          plan_name: subscription.plan_display_name,
          error_message: error_message,
          billing_url: "#{Discourse.base_url}/billing",
          support_url: "#{Discourse.base_url}/contact"
        }
      }
      
      Email::Sender.new(Email::Message.new(email_opts), :trial_expiration).send
    end
  end
end 