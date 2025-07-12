module Jobs
  class NotifyUserOfReferralReward < ::Jobs::Base
    def execute(args)
      action = args[:action]
      
      case action
      when 'referral_completed'
        handle_referral_completed(args)
      when 'reward_applied'
        handle_reward_applied(args)
      end
    end
    
    private
    
    def handle_referral_completed(args)
      referral_id = args[:referral_id]
      return unless referral_id
      
      referral = UserReferral.find(referral_id)
      return unless referral
      
      # Send email to referrer about completed referral
      send_referral_completed_email(referral)
    end
    
    def handle_reward_applied(args)
      reward_id = args[:reward_id]
      return unless reward_id
      
      reward = ReferralReward.find(reward_id)
      return unless reward
      
      # Send email to user about applied reward
      send_reward_applied_email(reward)
    end
    
    def send_referral_completed_email(referral)
      email_template = create_referral_completed_email(referral)
      
      Jobs.enqueue(:user_email,
        to_address: referral.referrer.email,
        email_type: 'referral_completed',
        user_id: referral.referrer.id,
        template: email_template
      )
    end
    
    def send_reward_applied_email(reward)
      email_template = create_reward_applied_email(reward)
      
      Jobs.enqueue(:user_email,
        to_address: reward.user.email,
        email_type: 'referral_reward_applied',
        user_id: reward.user.id,
        template: email_template
      )
    end
    
    def create_referral_completed_email(referral)
      <<~EMAIL
        Referral Completed - You've Earned a Free Month!
        
        Dear #{referral.referrer.username},
        
        Great news! Your referral has been completed successfully.
        
        **Referral Details:**
        - Referred User: #{referral.referred_user.username}
        - Completion Date: #{referral.completed_at.strftime('%Y-%m-%d %H:%M UTC')}
        - Reward: 1 month free subscription
        
        **What happens next:**
        Your subscription has been automatically extended by 1 month. This extension will be applied to your next billing cycle.
        
        **Thank you for helping grow our community!**
        Your referral helps maintain the high quality of our executive network.
        
        If you have any questions about your referral reward, please contact us at support@circleofpeers.net
        
        Best regards,
        The Circle of Peers Team
      EMAIL
    end
    
    def create_reward_applied_email(reward)
      <<~EMAIL
        Referral Reward Applied - Subscription Extended!
        
        Dear #{reward.user.username},
        
        Your referral reward has been successfully applied to your subscription.
        
        **Reward Details:**
        - Months Awarded: #{reward.months_awarded} month(s)
        - Applied Date: #{reward.applied_at.strftime('%Y-%m-%d %H:%M UTC')}
        - Reason: #{reward.reason}
        
        **What this means:**
        Your subscription has been extended by #{reward.months_awarded} month(s). You will not be charged for this period.
        
        **Current Subscription Status:**
        - Extended until: #{reward.user.subscriptions.active.first&.current_period_end&.strftime('%Y-%m-%d') || 'N/A'}
        
        Thank you for being part of our community!
        
        If you have any questions about your subscription, please contact us at billing@circleofpeers.net
        
        Best regards,
        The Circle of Peers Team
      EMAIL
    end
  end
end 