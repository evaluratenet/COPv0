class UserSession < ActiveRecord::Base
  belongs_to :user
  has_many :session_logs, dependent: :destroy
  
  validates :session_id, presence: true, uniqueness: true
  validates :user_id, presence: true
  validates :ip_address, presence: true
  validates :user_agent, presence: true
  
  scope :active, -> { where(active: true) }
  scope :expired, -> { where('last_activity < ?', 24.hours.ago) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  
  before_create :set_created_at
  before_save :update_last_activity
  
  def self.create_session(user, session_id, request)
    # Deactivate all other sessions for this user
    by_user(user.id).update_all(active: false, ended_at: Time.current)
    
    # Create new session
    create!(
      user_id: user.id,
      session_id: session_id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      active: true,
      last_activity: Time.current
    )
  end
  
  def self.deactivate_session(session_id)
    session = find_by(session_id: session_id)
    return unless session
    
    session.update!(
      active: false,
      ended_at: Time.current
    )
    
    # Log the session end
    session.session_logs.create!(
      action: 'logout',
      ip_address: session.ip_address,
      user_agent: session.user_agent
    )
  end
  
  def self.deactivate_all_user_sessions(user_id)
    sessions = by_user(user_id).active
    sessions.update_all(active: false, ended_at: Time.current)
    
    # Log all session ends
    sessions.each do |session|
      session.session_logs.create!(
        action: 'force_logout',
        ip_address: session.ip_address,
        user_agent: session.user_agent
      )
    end
  end
  
  def self.cleanup_expired_sessions
    expired_sessions = expired.active
    expired_sessions.update_all(active: false, ended_at: Time.current)
    
    # Log expired sessions
    expired_sessions.each do |session|
      session.session_logs.create!(
        action: 'expired',
        ip_address: session.ip_address,
        user_agent: session.user_agent
      )
    end
  end
  
  def self.active_session_count(user_id)
    by_user(user_id).active.count
  end
  
  def self.session_statistics
    {
      total_active: active.count,
      total_users_with_sessions: active.distinct.count(:user_id),
      sessions_by_user: active.group(:user_id).count,
      recent_activity: active.where('last_activity > ?', 1.hour.ago).count
    }
  end
  
  def update_activity!
    update!(last_activity: Time.current)
  end
  
  def duration
    return nil unless ended_at
    ended_at - created_at
  end
  
  def is_expired?
    last_activity < 24.hours.ago
  end
  
  def location_info
    # Basic location detection based on IP
    # In production, you might want to use a geolocation service
    case ip_address
    when /^127\.|^10\.|^192\.168\.|^172\.(1[6-9]|2[0-9]|3[0-1])\./
      'Local Network'
    else
      'External Network'
    end
  end
  
  private
  
  def set_created_at
    self.created_at ||= Time.current
  end
  
  def update_last_activity
    self.last_activity = Time.current if active?
  end
end 