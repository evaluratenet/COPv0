module Jobs
  class ProcessReferralReward < ::Jobs::Base
    def execute(args)
      referral_id = args[:referral_id]
      return unless referral_id
      
      referral = UserReferral.find(referral_id)
      return unless referral
      
      # Check if referral can be completed
      if referral.can_be_completed?
        referral.complete!
        
        # Notify referrer of reward
        Jobs.enqueue(:notify_user_of_referral_reward,
          referral_id: referral.id,
          action: 'referral_completed'
        )
      end
    end
  end
end 