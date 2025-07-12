class SupportTicket < ActiveRecord::Base
  belongs_to :user
  belongs_to :assigned_to, class_name: 'User', optional: true
  
  validates :ticket_number, presence: true, uniqueness: true
  validates :subject, presence: true
  validates :category, inclusion: { in: %w[general billing technical moderation verification account] }
  validates :priority, inclusion: { in: %w[low medium high urgent] }
  validates :status, inclusion: { in: %w[open in_progress waiting_on_user resolved closed] }
  
  scope :open, -> { where(status: 'open') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :resolved, -> { where(status: 'resolved') }
  scope :closed, -> { where(status: 'closed') }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  scope :urgent, -> { where(priority: 'urgent') }
  
  before_create :generate_ticket_number
  after_create :create_helpdeskz_ticket
  after_update :update_helpdeskz_ticket, if: :saved_change_to_status?
  
  def self.categories
    {
      'general' => 'General Support',
      'billing' => 'Billing & Payments',
      'technical' => 'Technical Issues',
      'moderation' => 'Content Moderation',
      'verification' => 'Account Verification',
      'account' => 'Account Management'
    }
  end
  
  def self.priorities
    {
      'low' => 'Low',
      'medium' => 'Medium',
      'high' => 'High',
      'urgent' => 'Urgent'
    }
  end
  
  def self.statuses
    {
      'open' => 'Open',
      'in_progress' => 'In Progress',
      'waiting_on_user' => 'Waiting on User',
      'resolved' => 'Resolved',
      'closed' => 'Closed'
    }
  end
  
  def self.generate_ticket_number
    # Generate unique ticket number: TKT-YYYYMMDD-XXXX
    date_prefix = Time.current.strftime('%Y%m%d')
    last_ticket = where("ticket_number LIKE ?", "TKT-#{date_prefix}-%")
                   .order(ticket_number: :desc)
                   .first
    
    if last_ticket
      last_number = last_ticket.ticket_number.split('-').last.to_i
      sequence = (last_number + 1).to_s.rjust(4, '0')
    else
      sequence = '0001'
    end
    
    "TKT-#{date_prefix}-#{sequence}"
  end
  
  def self.create_for_user(user, subject, description, category = 'general', priority = 'medium')
    create!(
      user: user,
      subject: subject,
      description: description,
      category: category,
      priority: priority,
      status: 'open'
    )
  end
  
  def assign_to!(admin_user)
    update!(
      assigned_to: admin_user,
      status: 'in_progress'
    )
  end
  
  def resolve!(admin_user, resolution_notes = nil)
    update!(
      status: 'resolved',
      resolved_at: Time.current,
      assigned_to: admin_user
    )
    
    # Add resolution notes to metadata
    metadata_data = metadata || {}
    metadata_data['resolution_notes'] = resolution_notes
    metadata_data['resolved_by'] = admin_user.username
    update!(metadata: metadata_data)
    
    # Notify user of resolution
    Jobs.enqueue(:ticket_resolved_notification, ticket_id: id)
  end
  
  def close!(admin_user)
    update!(
      status: 'closed',
      assigned_to: admin_user
    )
  end
  
  def reopen!
    update!(
      status: 'open',
      resolved_at: nil
    )
  end
  
  def time_since_created
    ((Time.current - created_at) / 1.hour).round(1)
  end
  
  def time_since_updated
    ((Time.current - updated_at) / 1.hour).round(1)
  end
  
  def is_urgent?
    priority == 'urgent' || (priority == 'high' && status == 'open' && time_since_created > 24)
  end
  
  def requires_immediate_attention?
    priority == 'urgent' || (priority == 'high' && status == 'open')
  end
  
  def category_display
    self.class.categories[category] || category.humanize
  end
  
  def priority_display
    self.class.priorities[priority] || priority.humanize
  end
  
  def status_display
    self.class.statuses[status] || status.humanize
  end
  
  def priority_color
    case priority
    when 'urgent' then 'danger'
    when 'high' then 'warning'
    when 'medium' then 'info'
    when 'low' then 'success'
    else 'secondary'
    end
  end
  
  def status_color
    case status
    when 'open' then 'danger'
    when 'in_progress' then 'warning'
    when 'waiting_on_user' then 'info'
    when 'resolved' then 'success'
    when 'closed' then 'secondary'
    else 'secondary'
    end
  end
  
  private
  
  def generate_ticket_number
    return if ticket_number.present?
    self.ticket_number = self.class.generate_ticket_number
  end
  
  def create_helpdeskz_ticket
    # Create ticket in HelpdeskZ system
    Jobs.enqueue(:create_helpdeskz_ticket, ticket_id: id)
  end
  
  def update_helpdeskz_ticket
    # Update ticket in HelpdeskZ system
    Jobs.enqueue(:update_helpdeskz_ticket, ticket_id: id)
  end
end 