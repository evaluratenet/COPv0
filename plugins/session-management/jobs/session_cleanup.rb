module Jobs
  class SessionCleanup < ::Jobs::Base
    sidekiq_options retry: false
    
    def execute(args)
      # Clean up expired sessions (24 hours)
      UserSession.cleanup_expired_sessions
      
      # Check for inactivity timeouts (10 minutes + 5 minutes grace period)
      timeout_sessions = UserSession.active.where('last_activity < ?', 15.minutes.ago)
      
      timeout_sessions.each do |session|
        # Check if we already sent a warning
        warning_sent = session.session_logs
                              .by_action('inactivity_warning')
                              .where('created_at > ?', 10.minutes.ago)
                              .exists?
        
        if !warning_sent && session.last_activity < 10.minutes.ago
          # Send inactivity warning
          SessionLog.log_action(session, 'inactivity_warning')
          
          # Send notification to user
          Jobs.enqueue(:session_notification, 
            user_id: session.user_id,
            action: 'inactivity_warning',
            session_id: session.session_id
          )
        elsif session.last_activity < 15.minutes.ago
          # Force logout after 15 minutes of inactivity
          session.update!(active: false, ended_at: Time.current)
          
          # Log the timeout
          SessionLog.log_action(session, 'inactivity_timeout')
          
          # Send notification to user
          Jobs.enqueue(:session_notification, 
            user_id: session.user_id,
            action: 'inactivity_timeout',
            session_id: session.session_id
          )
        end
      end
      
      # Log cleanup statistics
      Rails.logger.info "Session cleanup completed: #{timeout_sessions.count} sessions timed out"
    end
  end
end 