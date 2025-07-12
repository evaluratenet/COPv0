class UserBlock < ActiveRecord::Base
  belongs_to :blocker, class_name: 'User'
  belongs_to :blocked_user, class_name: 'User'
  
  validates :blocker_id, presence: true
  validates :blocked_user_id, presence: true
  validates :active, inclusion: { in: [true, false] }
  validates :reason, length: { maximum: 500 }
  
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  
  before_create :validate_block
  after_update :handle_status_change
  
  def self.create_block(blocker, blocked_user, reason = nil)
    # Check if already blocked
    existing = find_by(blocker_id: blocker.id, blocked_user_id: blocked_user.id)
    if existing&.active?
      raise "User is already blocked"
    end
    
    # Create or reactivate block
    if existing
      existing.update!(
        active: true,
        reason: reason,
        blocked_at: Time.current,
        unblocked_at: nil
      )
      existing
    else
      create!(
        blocker_id: blocker.id,
        blocked_user_id: blocked_user.id,
        reason: reason,
        active: true
      )
    end
  end
  
  def deactivate!
    update!(
      active: false,
      unblocked_at: Time.current
    )
  end
  
  def reactivate!
    update!(
      active: true,
      blocked_at: Time.current,
      unblocked_at: nil
    )
  end
  
  def block_summary
    "Block: #{blocker.username} → #{blocked_user.username}"
  end
  
  def duration
    return nil unless blocked_at
    end_time = unblocked_at || Time.current
    ((end_time - blocked_at) / 1.day).round(1)
  end
  
  def is_recent?
    created_at > 7.days.ago
  end
  
  def is_long_term?
    duration && duration > 30
  end
  
  def block_reason_display
    if reason.present?
      reason
    else
      "No reason provided"
    end
  end
  
  def status_display
    if active?
      "Active"
    else
      "Removed"
    end
  end
  
  def can_be_removed_by?(user)
    return true if user&.admin?
    return true if user&.id == blocker_id
    false
  end
  
  def requires_admin_attention?
    active? && created_at < 7.days.ago && reason.blank?
  end
  
  private
  
  def validate_block
    # Ensure blocker and blocked are different
    if blocker_id == blocked_user_id
      errors.add(:base, "Cannot block yourself")
      throw(:abort)
    end
    
    # Ensure both users exist
    unless User.exists?(blocker_id) && User.exists?(blocked_user_id)
      errors.add(:base, "Invalid user specified")
      throw(:abort)
    end
  end
  
  def handle_status_change
    if active_previously_changed?
      if active?
        # Block activated
        Rails.logger.info "User block activated: #{blocker.username} → #{blocked_user.username}"
        
        # Send notification to blocked user
        Jobs.enqueue(:notify_user_of_block,
          block_id: id,
          action: 'blocked'
        )
      else
        # Block deactivated
        Rails.logger.info "User block deactivated: #{blocker.username} → #{blocked_user.username}"
        
        # Send notification to blocked user
        Jobs.enqueue(:notify_user_of_block,
          block_id: id,
          action: 'unblocked'
        )
      end
    end
  end
end 