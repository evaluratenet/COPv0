class ContactRequest < ActiveRecord::Base
  belongs_to :requester, class_name: 'User'
  belongs_to :target_user, class_name: 'User'
  belongs_to :approved_by, class_name: 'User', optional: true
  belongs_to :rejected_by, class_name: 'User', optional: true
  
  validates :requester_id, presence: true
  validates :target_user_id, presence: true
  validates :status, inclusion: { in: %w[pending approved rejected] }
  validates :message, length: { maximum: 1000 }
  
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  
  before_create :validate_contact_request
  after_update :handle_status_change
  
  def self.create_request(requester, target_user, message = nil)
    # Check if requester has active subscription
    unless requester.has_active_subscription?
      raise "Contact requests are only available to active subscribers"
    end
    
    # Check if target user is contactable
    unless target_user.contactable_by?(requester)
      raise "User is not accepting contact requests"
    end
    
    # Check if request already exists
    existing = find_by(requester_id: requester.id, target_user_id: target_user.id, status: 'pending')
    if existing
      raise "Contact request already pending"
    end
    
    # Create the request
    create!(
      requester_id: requester.id,
      target_user_id: target_user.id,
      message: message,
      status: 'pending'
    )
  end
  
  def approve!(admin_user = nil)
    update!(
      status: 'approved',
      approved_by: admin_user,
      approved_at: Time.current
    )
    
    # Send approval notifications
    Jobs.enqueue(:notify_user_of_contact_request, 
      request_id: id,
      action: 'approved'
    )
  end
  
  def reject!(admin_user = nil, reason = nil)
    update!(
      status: 'rejected',
      rejected_by: admin_user,
      rejected_at: Time.current,
      admin_notes: reason
    )
    
    # Send rejection notifications
    Jobs.enqueue(:notify_user_of_contact_request,
      request_id: id,
      action: 'rejected',
      reason: reason
    )
  end
  
  def can_be_approved_by?(user)
    return true if user&.admin?
    return true if user&.id == target_user_id
    false
  end
  
  def can_be_rejected_by?(user)
    can_be_approved_by?(user)
  end
  
  def request_summary
    "Contact request from #{requester.username} to #{target_user.username}"
  end
  
  def time_since_created
    ((Time.current - created_at) / 1.hour).round(1)
  end
  
  def is_old?
    created_at < 7.days.ago
  end
  
  def requires_admin_attention?
    status == 'pending' && created_at < 3.days.ago
  end
  
  private
  
  def validate_contact_request
    # Ensure requester and target are different
    if requester_id == target_user_id
      errors.add(:base, "Cannot send contact request to yourself")
      throw(:abort)
    end
    
    # Ensure target user is contactable
    unless target_user.contactable_by?(requester)
      errors.add(:base, "User is not accepting contact requests")
      throw(:abort)
    end
  end
  
  def handle_status_change
    if status_previously_changed? && status == 'approved'
      # Log the approval
      Rails.logger.info "Contact request approved: #{requester.username} → #{target_user.username}"
    elsif status_previously_changed? && status == 'rejected'
      # Log the rejection
      Rails.logger.info "Contact request rejected: #{requester.username} → #{target_user.username}"
    end
  end
end 