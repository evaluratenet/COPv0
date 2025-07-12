module Jobs
  class SubscriptionReminder < ::Jobs::Base
    sidekiq_options retry: 3
    
    def execute(args)
      reminder_type = args[:reminder_type]
      subscription_id = args[:subscription_id]
      
      subscription = Subscription.find(subscription_id)
      user = subscription.user
      
      case reminder_type
      when 'trial_ending'
        send_trial_ending_reminder(user, subscription)
      when 'billing_reminder'
        send_billing_reminder(user, subscription)
      when 'payment_method_expiring'
        send_payment_method_expiring_reminder(user, subscription)
      end
    end
    
    private
    
    def send_trial_ending_reminder(user, subscription)
      days_remaining = subscription.trial_days_remaining
      
      email_opts = {
        to: user.email,
        subject: I18n.t('billing.reminders.trial_ending.subject', days: days_remaining),
        template: 'subscription_trial_ending',
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
      
      Email::Sender.new(Email::Message.new(email_opts), :subscription_reminder).send
    end
    
    def send_billing_reminder(user, subscription)
      days_until_billing = ((subscription.next_billing_date - Time.current) / 1.day).ceil
      
      email_opts = {
        to: user.email,
        subject: I18n.t('billing.reminders.billing_reminder.subject', days: days_until_billing),
        template: 'subscription_billing_reminder',
        template_vars: {
          username: user.username,
          peer_id: user.custom_fields['peer_id'],
          days_until_billing: days_until_billing,
          billing_date: subscription.next_billing_date.strftime('%B %d, %Y'),
          amount: subscription.amount_in_dollars,
          plan_name: subscription.plan_display_name,
          billing_url: "#{Discourse.base_url}/billing",
          payment_method_url: "#{Discourse.base_url}/billing/payment_method"
        }
      }
      
      Email::Sender.new(Email::Message.new(email_opts), :subscription_reminder).send
    end
    
    def send_payment_method_expiring_reminder(user, subscription)
      payment_method = subscription.payment_methods.default.first
      return unless payment_method&.expires_soon?
      
      email_opts = {
        to: user.email,
        subject: I18n.t('billing.reminders.payment_method_expiring.subject'),
        template: 'payment_method_expiring',
        template_vars: {
          username: user.username,
          peer_id: user.custom_fields['peer_id'],
          payment_method_name: payment_method.display_name,
          expiry_date: payment_method.expiry_display,
          billing_url: "#{Discourse.base_url}/billing",
          payment_method_url: "#{Discourse.base_url}/billing/payment_method"
        }
      }
      
      Email::Sender.new(Email::Message.new(email_opts), :subscription_reminder).send
    end
  end
end 