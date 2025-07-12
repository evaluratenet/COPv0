class ReferralReward < ActiveRecord::Base
  belongs_to :user
  belongs_to :referral, class_name: 'UserReferral'
  
  validates :user_id, presence: true
  validates :referral_id, presence: true
  validates :months_awarded, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending applied expired] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :applied, -> { where(status: 'applied') }
  scope :expired, -> { where(status: 'expired') }
  scope :recent, -> { where('created_at > ?', 90.days.ago) }
  
  before_create :set_defaults
  after_update :handle_status_change
  
  def self.create_reward(user, referral, months = 1)
    create!(
      user_id: user.id,
      referral_id: referral.id,
      months_awarded: months,
      reason: "Referral reward for #{referral.referred_user.username}",
      status: 'pending'
    )
  end
  
  def apply!
    update!(
      status: 'applied',
      applied_at: Time.current
    )
    
    # Extend user's subscription by the awarded months
    extend_user_subscription
  end
  
  def expire!
    update!(
      status: 'expired',
      expired_at: Time.current
    )
  end
  
  def extend_user_subscription
    subscription = Subscription.find_by(user_id: user.id)
    return unless subscription
    
    # Calculate new end date
    current_end = subscription.end_date || Time.current
    new_end = current_end + months_awarded.months
    
    # Update subscription
    subscription.update!(
      end_date: new_end,
      extended_by_referral: true
    )
    
    # Log the extension
    Rails.logger.info "Extended subscription for #{user.username} by #{months_awarded} month(s) via referral reward"
  end
  
  def reward_summary
    "#{months_awarded} month(s) free for referring #{referral.referred_user.username}"
  end
  
  def time_since_created
    ((Time.current - created_at) / 1.day).round(1)
  end
  
  def is_recent?
    created_at > 30.days.ago
  end
  
  def can_be_applied?
    status == 'pending' && user.has_active_subscription?
  end
  
  def can_be_expired?
    status == 'pending' && created_at < 90.days.ago
  end
  
  def value_in_dollars
    months_awarded * 50 # Assuming $50/month subscription
  end
  
  private
  
  def set_defaults
    self.status ||= 'pending'
  end
  
  def handle_status_change
    if status_previously_changed? && status == 'applied'
      Rails.logger.info "Referral reward applied: #{user.username} received #{months_awarded} month(s) free"
      
      # Notify user of reward application
      Jobs.enqueue(:notify_user_of_referral_reward,
        reward_id: id,
        action: 'applied'
      )
    elsif status_previously_changed? && status == 'expired'
      Rails.logger.info "Referral reward expired: #{user.username} - #{months_awarded} month(s) free"
    end
  end
end 