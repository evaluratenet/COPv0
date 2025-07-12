class UserReferral < ActiveRecord::Base
  belongs_to :referrer, class_name: 'User'
  belongs_to :referred_user, class_name: 'User'
  has_one :referral_reward, dependent: :destroy
  
  validates :referrer_id, presence: true
  validates :referred_user_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending active completed expired] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :expired, -> { where(status: 'expired') }
  scope :recent, -> { where('created_at > ?', 90.days.ago) }
  
  before_create :set_defaults
  after_update :handle_status_change
  
  def self.create_referral(referrer_email, referred_user)
    # Find referrer by email
    referrer = User.find_by(email: referrer_email.downcase)
    return nil unless referrer
    
    # Check if referrer is an active subscriber
    unless referrer.has_active_subscription?
      return nil
    end
    
    # Check if referral already exists
    existing = find_by(referred_user_id: referred_user.id)
    return existing if existing
    
    # Create referral
    create!(
      referrer_id: referrer.id,
      referred_user_id: referred_user.id,
      referrer_email: referrer_email.downcase,
      status: 'pending'
    )
  end
  
  def self.find_by_referrer_email(email)
    where(referrer_email: email.downcase)
  end
  
  def activate!
    update!(status: 'active')
  end
  
  def complete!
    update!(status: 'completed')
    
    # Create referral reward for referrer
    ReferralReward.create_reward(referrer, self)
  end
  
  def expire!
    update!(status: 'expired')
  end
  
  def referral_summary
    "Referral: #{referrer.username} → #{referred_user.username}"
  end
  
  def time_since_created
    ((Time.current - created_at) / 1.day).round(1)
  end
  
  def is_recent?
    created_at > 30.days.ago
  end
  
  def can_be_completed?
    status == 'active' && referred_user.has_active_subscription?
  end
  
  def can_be_expired?
    status == 'pending' && created_at < 90.days.ago
  end
  
  private
  
  def set_defaults
    self.status ||= 'pending'
  end
  
  def handle_status_change
    if status_previously_changed? && status == 'completed'
      Rails.logger.info "Referral completed: #{referrer.username} referred #{referred_user.username}"
      
      # Notify referrer of completed referral
      Jobs.enqueue(:notify_user_of_referral_reward,
        referral_id: id,
        action: 'referral_completed'
      )
    elsif status_previously_changed? && status == 'expired'
      Rails.logger.info "Referral expired: #{referrer.username} → #{referred_user.username}"
    end
  end
end