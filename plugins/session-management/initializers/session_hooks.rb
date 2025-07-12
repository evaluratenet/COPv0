# Session Management Hooks
# Integrates with Discourse's authentication system

after_initialize do
  # Hook into user login
  on(:user_logged_in) do |user, session_id, request|
    next unless user && session_id && request
    
    # Create new session record
    UserSession.create_session(user, session_id, request)
    
    # Log the login
    session_record = UserSession.find_by(session_id: session_id)
    if session_record
      SessionLog.log_action(session_record, 'login', request)
    end
    
    # Send welcome notification
    Jobs.enqueue(:session_notification, 
      user_id: user.id,
      action: 'login',
      session_id: session_id
    )
  end
  
  # Hook into user logout
  on(:user_logged_out) do |user, session_id|
    next unless user && session_id
    
    # Deactivate session
    UserSession.deactivate_session(session_id)
  end
  
  # Hook into session validation
  on(:session_validate) do |session_id, user|
    next unless session_id && user
    
    session_record = UserSession.find_by(session_id: session_id)
    
    if session_record&.active?
      # Update activity
      session_record.update_activity!
      
      # Check for inactivity warning
      if session_record.last_activity < 10.minutes.ago
        # Send inactivity warning if not already sent
        warning_sent = session_record.session_logs
                                    .by_action('inactivity_warning')
                                    .where('created_at > ?', 10.minutes.ago)
                                    .exists?
        
        unless warning_sent
          SessionLog.log_action(session_record, 'inactivity_warning')
          
          Jobs.enqueue(:session_notification, 
            user_id: user.id,
            action: 'inactivity_warning',
            session_id: session_id
          )
        end
      end
      
      # Check for timeout
      if session_record.last_activity < 15.minutes.ago
        # Force logout
        session_record.update!(active: false, ended_at: Time.current)
        SessionLog.log_action(session_record, 'inactivity_timeout')
        
        Jobs.enqueue(:session_notification, 
          user_id: user.id,
          action: 'inactivity_timeout',
          session_id: session_id
        )
        
        # Return false to invalidate session
        return false
      end
      
      return true
    else
      return false
    end
  end
  
  # Schedule cleanup job
  if defined?(Sidekiq)
    Sidekiq::Cron::Job.create(
      name: 'Session Cleanup - every 5 minutes',
      cron: '*/5 * * * *',
      class: 'Jobs::SessionCleanup'
    )
  end
  
  # Add session management to user serializer
  UserSerializer.class_eval do
    attributes :active_sessions_count, :last_session_activity
    
    def active_sessions_count
      UserSession.active_session_count(object.id)
    end
    
    def last_session_activity
      session = UserSession.active.by_user(object.id).order(last_activity: :desc).first
      session&.last_activity
    end
  end
  
  # Add session management to current user serializer
  CurrentUserSerializer.class_eval do
    attributes :session_status, :inactivity_warning
    
    def session_status
      return 'not_logged_in' unless scope.current_user
      
      session_record = UserSession.find_by(session_id: scope.session[:session_id])
      return 'inactive' unless session_record&.active?
      
      if session_record.last_activity < 10.minutes.ago
        'inactivity_warning'
      else
        'active'
      end
    end
    
    def inactivity_warning
      return false unless scope.current_user
      
      session_record = UserSession.find_by(session_id: scope.session[:session_id])
      return false unless session_record&.active?
      
      session_record.last_activity < 10.minutes.ago
    end
  end
end 