class SessionLog < ActiveRecord::Base
  belongs_to :user_session
  
  validates :action, presence: true
  validates :ip_address, presence: true
  validates :user_agent, presence: true
  
  scope :recent, -> { where('created_at > ?', 24.hours.ago) }
  scope :by_action, ->(action) { where(action: action) }
  
  ACTIONS = %w[login logout force_logout expired inactivity_warning inactivity_timeout]
  
  def self.log_action(session, action, request = nil)
    create!(
      user_session: session,
      action: action,
      ip_address: request&.remote_ip || session.ip_address,
      user_agent: request&.user_agent || session.user_agent,
      metadata: {
        timestamp: Time.current,
        action: action,
        session_id: session.session_id
      }
    )
  end
  
  def self.inactivity_warnings_count(user_id, time_period = 1.hour)
    joins(:user_session)
      .where(user_sessions: { user_id: user_id })
      .by_action('inactivity_warning')
      .where('created_at > ?', time_period.ago)
      .count
  end
end 