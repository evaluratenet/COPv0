class SessionController < ApplicationController
  before_action :ensure_logged_in, except: [:status]
  
  def status
    if current_user
      session = UserSession.find_by(session_id: session[:session_id])
      
      if session&.active?
        session.update_activity!
        
        # Check for inactivity warning (10 minutes)
        if session.last_activity < 10.minutes.ago
          render json: {
            status: 'inactivity_warning',
            message: 'You have been inactive for 10 minutes. Click "Continue Session" to stay logged in.',
            last_activity: session.last_activity,
            inactive_since: 10.minutes.ago
          }
        else
          render json: {
            status: 'active',
            last_activity: session.last_activity,
            session_id: session.session_id
          }
        end
      else
        render json: { status: 'inactive' }
      end
    else
      render json: { status: 'not_logged_in' }
    end
  end
  
  def force_logout_others
    if current_user
      UserSession.deactivate_all_user_sessions(current_user.id)
      
      # Log the action
      current_session = UserSession.find_by(session_id: session[:session_id])
      if current_session
        SessionLog.log_action(current_session, 'force_logout_others', request)
      end
      
      render json: { success: true, message: 'All other sessions have been terminated.' }
    else
      render json: { success: false, message: 'You must be logged in to perform this action.' }, status: 401
    end
  end
  
  def extend_session
    if current_user
      session_record = UserSession.find_by(session_id: session[:session_id])
      
      if session_record&.active?
        session_record.update_activity!
        
        # Log the session extension
        SessionLog.log_action(session_record, 'session_extended', request)
        
        render json: {
          success: true,
          message: 'Session extended successfully.',
          last_activity: session_record.last_activity
        }
      else
        render json: { success: false, message: 'No active session found.' }, status: 404
      end
    else
      render json: { success: false, message: 'You must be logged in to perform this action.' }, status: 401
    end
  end
  
  def inactivity_response
    if current_user
      session_record = UserSession.find_by(session_id: session[:session_id])
      
      if session_record&.active?
        session_record.update_activity!
        
        # Log the user's response to inactivity warning
        SessionLog.log_action(session_record, 'inactivity_response', request)
        
        render json: {
          success: true,
          message: 'Session continued successfully.',
          last_activity: session_record.last_activity
        }
      else
        render json: { success: false, message: 'No active session found.' }, status: 404
      end
    else
      render json: { success: false, message: 'You must be logged in to perform this action.' }, status: 401
    end
  end
end 