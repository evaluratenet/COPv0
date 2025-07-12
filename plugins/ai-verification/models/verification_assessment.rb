class VerificationAssessment < ActiveRecord::Base
  belongs_to :user
  belongs_to :reviewed_by, class_name: 'User', optional: true
  
  validates :user_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending approved rejected needs_info] }
  validates :confidence_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true
  
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :needs_info, -> { where(status: 'needs_info') }
  scope :by_confidence, ->(min_score) { where('confidence_score >= ?', min_score) }
  scope :recent, -> { where('created_at > ?', 7.days.ago) }
  
  before_create :set_defaults
  after_update :handle_status_change
  
  def self.create_for_user(user)
    # Check if assessment already exists
    existing = find_by(user_id: user.id)
    return existing if existing
    
    # Create new assessment
    create!(
      user_id: user.id,
      status: 'pending',
      verification_data: collect_verification_data(user)
    )
  end
  
  def self.collect_verification_data(user)
    {
      email: user.email,
      username: user.username,
      name: user.name,
      title: user.title,
      company: user.company,
      linkedin_url: user.linkedin_url,
      bio: user.bio,
      location: user.location,
      website: user.website,
      created_at: user.created_at,
      last_seen_at: user.last_seen_at,
      trust_level: user.trust_level,
      moderator: user.moderator?,
      admin: user.admin?
    }
  end
  
  def approve!(admin_user, notes = nil)
    update!(
      status: 'approved',
      reviewed_by: admin_user,
      reviewed_at: Time.current,
      approved_at: Time.current,
      admin_notes: notes
    )
    
    # Trigger user approval
    user.update!(approved: true, approved_at: Time.current)
    
    # Send approval notification
    Jobs.enqueue(:user_approved_notification, user_id: user.id)
  end
  
  def reject!(admin_user, reason = nil, notes = nil)
    update!(
      status: 'rejected',
      reviewed_by: admin_user,
      reviewed_at: Time.current,
      rejected_at: Time.current,
      admin_notes: notes
    )
    
    # Send rejection notification
    Jobs.enqueue(:user_rejected_notification, user_id: user.id, reason: reason)
  end
  
  def request_info!(admin_user, requested_info = nil, notes = nil)
    update!(
      status: 'needs_info',
      reviewed_by: admin_user,
      reviewed_at: Time.current,
      admin_notes: notes
    )
    
    # Send info request notification
    Jobs.enqueue(:user_info_request_notification, user_id: user.id, requested_info: requested_info)
  end
  
  def ai_recommendation_display
    return 'No recommendation available' unless ai_recommendation.present?
    
    case confidence_score
    when 0.8..1.0
      "✅ **Vera: Strong Approval** (#{(confidence_score * 100).round}% confidence)"
    when 0.6..0.79
      "✅ **Vera: Approve** (#{(confidence_score * 100).round}% confidence)"
    when 0.4..0.59
      "⚠️ **Vera: Review Required** (#{(confidence_score * 100).round}% confidence)"
    when 0.2..0.39
      "❌ **Vera: Likely Reject** (#{(confidence_score * 100).round}% confidence)"
    else
      "❌ **Vera: Strong Reject** (#{(confidence_score * 100).round}% confidence)"
    end
  end
  
  def risk_factors_display
    return 'No risk factors identified' unless risk_factors.present?
    
    risk_factors.map do |factor|
      case factor['severity']
      when 'high'
        "🔴 **#{factor['name']}**: #{factor['description']}"
      when 'medium'
        "🟡 **#{factor['name']}**: #{factor['description']}"
      when 'low'
        "🟢 **#{factor['name']}**: #{factor['description']}"
      end
    end.join("\n")
  end
  
  def verification_summary
    {
      user_info: {
        name: user.name,
        email: user.email,
        company: user.company,
        title: user.title,
        linkedin: user.linkedin_url
      },
      assessment: {
        status: status,
        ai_recommendation: ai_recommendation_display,
        confidence_score: confidence_score,
        risk_factors: risk_factors_display,
        created_at: created_at,
        reviewed_at: reviewed_at
      },
      admin_decision: {
        reviewed_by: reviewed_by&.username,
        admin_notes: admin_notes,
        approved_at: approved_at,
        rejected_at: rejected_at
      }
    }
  end
  
  def time_since_created
    ((Time.current - created_at) / 1.hour).round(1)
  end
  
  def requires_immediate_attention?
    status == 'pending' && created_at < 24.hours.ago
  end
  
  def high_confidence_approval?
    confidence_score && confidence_score >= 0.8 && ai_recommendation&.include?('approve')
  end
  
  def high_confidence_rejection?
    confidence_score && confidence_score >= 0.8 && ai_recommendation&.include?('reject')
  end
  
  private
  
  def set_defaults
    self.status ||= 'pending'
  end
  
  def handle_status_change
    if status_previously_changed? && status == 'approved'
      # Trigger peer ID assignment
      Jobs.enqueue(:assign_peer_id, user_id: user.id)
    end
  end
end 