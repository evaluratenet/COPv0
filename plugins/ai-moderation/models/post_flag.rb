class PostFlag < ActiveRecord::Base
  belongs_to :post
  belongs_to :flagged_by_user, class_name: 'User', optional: true
  belongs_to :violation_type
  belongs_to :reviewed_by_admin, class_name: 'User', optional: true
  
  validates :post_id, presence: true
  validates :violation_type_id, presence: true
  validates :source, inclusion: { in: %w[user ai admin] }
  validates :status, inclusion: { in: %w[pending approved rejected resolved] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :resolved, -> { where(status: 'resolved') }
  scope :by_source, ->(source) { where(source: source) }
  scope :by_violation_type, ->(type_id) { where(violation_type_id: type_id) }
  scope :recent, -> { where('created_at > ?', 7.days.ago) }
  
  before_create :set_defaults
  after_create :update_post_flag_count
  after_update :handle_status_change
  
  def self.create_ai_flag(post, violation_type, reason, confidence = nil)
    create!(
      post_id: post.id,
      violation_type: violation_type,
      reason: reason,
      source: 'ai',
      status: 'pending',
      confidence: confidence
    )
  end
  
  def self.create_user_flag(post, user, violation_type, reason)
    create!(
      post_id: post.id,
      flagged_by_user_id: user.id,
      flagged_by_peer_id: user.custom_fields['peer_id'],
      violation_type: violation_type,
      reason: reason,
      source: 'user',
      status: 'pending'
    )
  end
  
  def approve!(admin_user, notes = nil)
    update!(
      status: 'approved',
      reviewed_by_admin_id: admin_user.id,
      reviewed_at: Time.current,
      admin_notes: notes
    )
    
    # Take action on the post
    handle_approved_flag
  end
  
  def reject!(admin_user, notes = nil)
    update!(
      status: 'rejected',
      reviewed_by_admin_id: admin_user.id,
      reviewed_at: Time.current,
      admin_notes: notes
    )
  end
  
  def resolve!(admin_user, notes = nil)
    update!(
      status: 'resolved',
      reviewed_by_admin_id: admin_user.id,
      reviewed_at: Time.current,
      admin_notes: notes
    )
  end
  
  def suspend_user!(admin_user, notes = nil)
    update!(
      status: 'approved',
      reviewed_by_admin_id: admin_user.id,
      reviewed_at: Time.current,
      admin_notes: notes
    )
    
    # Suspend the user
    if post.user
      post.user.update!(suspended_at: Time.current, suspended_till: 30.days.from_now)
    end
  end
  
  def severity_level
    violation_type.severity
  end
  
  def is_ai_flag?
    source == 'ai'
  end
  
  def is_user_flag?
    source == 'user'
  end
  
  def is_admin_flag?
    source == 'admin'
  end
  
  def flagged_by_peer_display
    flagged_by_peer_id || 'AI System'
  end
  
  def reviewed_by_admin_display
    reviewed_by_admin&.username || 'System'
  end
  
  def time_since_flagged
    ((Time.current - created_at) / 1.hour).round(1)
  end
  
  def requires_immediate_attention?
    severity_level >= 4 && status == 'pending'
  end
  
  private
  
  def set_defaults
    self.status ||= 'pending'
  end
  
  def update_post_flag_count
    post.increment!(:flag_count)
    post.update!(last_flagged_at: Time.current)
  end
  
  def handle_status_change
    if status_previously_changed? && status == 'approved'
      handle_approved_flag
    end
  end
  
  def handle_approved_flag
    case severity_level
    when 5 # Critical - delete post and suspend user
      post.destroy!
      if post.user
        post.user.update!(suspended_at: Time.current, suspended_till: 30.days.from_now)
      end
    when 4 # High - hide post and warn user
      post.update!(hidden: true, hidden_reason_id: PostActionType.types[:inappropriate])
      # Send warning email to user
      Jobs.enqueue(:user_email,
        to_address: post.user.email,
        email_type: 'post_hidden_violation',
        user_id: post.user.id,
        post_id: post.id
      )
    when 3 # Medium - hide post
      post.update!(hidden: true, hidden_reason_id: PostActionType.types[:inappropriate])
    when 2 # Low - flag for review
      # Post remains visible but flagged
    end
  end
end 