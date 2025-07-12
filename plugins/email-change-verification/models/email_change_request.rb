class EmailChangeRequest < ActiveRecord::Base
  belongs_to :user
  belongs_to :approved_by, class_name: 'User', optional: true
  belongs_to :rejected_by, class_name: 'User', optional: true
  
  validates :user_id, presence: true
  validates :old_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :new_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :change_type, inclusion: { in: %w[corporate_to_private private_to_corporate corporate_to_corporate] }
  validates :status, inclusion: { in: %w[pending approved rejected] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :requires_approval, -> { where(requires_admin_approval: true) }
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  
  before_create :generate_verification_token
  after_update :handle_status_change
  
  def self.create_for_user(user, new_email)
    change_type = determine_change_type(user.email, new_email)
    requires_approval = change_type == 'corporate_to_private' && !user.has_corporate_email_backup?
    
    create!(
      user_id: user.id,
      old_email: user.email,
      new_email: new_email,
      change_type: change_type,
      status: 'pending',
      requires_admin_approval: requires_approval,
      verification_token: SecureRandom.hex(32)
    )
  end
  
  def self.determine_change_type(old_email, new_email)
    old_corporate = corporate_email?(old_email)
    new_corporate = corporate_email?(new_email)
    
    if old_corporate && !new_corporate
      'corporate_to_private'
    elsif !old_corporate && new_corporate
      'private_to_corporate'
    else
      'corporate_to_corporate'
    end
  end
  
  def self.corporate_email?(email)
    personal_domains = [
      'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com',
      'aol.com', 'icloud.com', 'protonmail.com', 'mail.com'
    ]
    domain = email.split('@').last&.downcase
    !personal_domains.include?(domain)
  end
  
  def approve!(admin_user)
    update!(
      status: 'approved',
      approved_by: admin_user,
      approved_at: Time.current,
      admin_notes: admin_notes
    )
    
    # Update user email
    user.update!(email: new_email)
    
    # Send approval notification
    Jobs.enqueue(:notify_user_of_email_change_approval, 
      user_id: user.id, 
      request_id: id
    )
  end
  
  def reject!(admin_user, reason = nil)
    update!(
      status: 'rejected',
      rejected_by: admin_user,
      rejected_at: Time.current,
      admin_notes: reason
    )
    
    # Send rejection notification
    Jobs.enqueue(:notify_user_of_email_change_rejection,
      user_id: user.id,
      request_id: id,
      reason: reason
    )
  end
  
  def requires_verification?
    change_type == 'corporate_to_private' && !user.has_corporate_email_backup?
  end
  
  def can_auto_approve?
    !requires_admin_approval
  end
  
  def verification_url
    "#{Discourse.base_url}/email-change/verify/#{verification_token}"
  end
  
  def change_summary
    case change_type
    when 'corporate_to_private'
      "Corporate email (#{old_email}) → Private email (#{new_email})"
    when 'private_to_corporate'
      "Private email (#{old_email}) → Corporate email (#{new_email})"
    else
      "Corporate email change: #{old_email} → #{new_email}"
    end
  end
  
  def risk_assessment
    case change_type
    when 'corporate_to_private'
      if user.has_corporate_email_backup?
        'low'
      else
        'high'
      end
    when 'private_to_corporate'
      'low'
    else
      'medium'
    end
  end
  
  def time_since_created
    ((Time.current - created_at) / 1.hour).round(1)
  end
  
  private
  
  def generate_verification_token
    self.verification_token = SecureRandom.hex(32)
  end
  
  def handle_status_change
    if status_previously_changed? && status == 'approved'
      # Log the email change
      Rails.logger.info "Email change approved for user #{user_id}: #{old_email} → #{new_email}"
    elsif status_previously_changed? && status == 'rejected'
      # Log the rejection
      Rails.logger.info "Email change rejected for user #{user_id}: #{old_email} → #{new_email}"
    end
  end
end 