class Admin::SessionsController < Admin::AdminController
  def index
    @sessions = UserSession.active.includes(:user, :session_logs)
                           .order(created_at: :desc)
                           .page(params[:page])
    
    @statistics = UserSession.session_statistics
    
    respond_to do |format|
      format.html
      format.json { render json: @sessions }
    end
  end
  
  def show
    @session = UserSession.includes(:user, :session_logs).find(params[:id])
    @logs = @session.session_logs.order(created_at: :desc).limit(50)
    
    respond_to do |format|
      format.html
      format.json { render json: @session }
    end
  end
  
  def destroy
    @session = UserSession.find(params[:id])
    
    if @session.update(active: false, ended_at: Time.current)
      # Log the admin action
      SessionLog.log_action(@session, 'admin_force_logout', request)
      
      # Send notification to user
      Jobs.enqueue(:session_notification, 
        user_id: @session.user_id,
        action: 'admin_force_logout',
        session_id: @session.session_id
      )
      
      render json: { success: true, message: 'Session terminated successfully.' }
    else
      render json: { success: false, message: 'Failed to terminate session.' }, status: 422
    end
  end
  
  def force_logout
    @session = UserSession.find(params[:id])
    
    if @session.update(active: false, ended_at: Time.current)
      # Log the admin action
      SessionLog.log_action(@session, 'admin_force_logout', request)
      
      # Send notification to user
      Jobs.enqueue(:session_notification, 
        user_id: @session.user_id,
        action: 'admin_force_logout',
        session_id: @session.session_id
      )
      
      render json: { success: true, message: 'Session terminated successfully.' }
    else
      render json: { success: false, message: 'Failed to terminate session.' }, status: 422
    end
  end
  
  def bulk_force_logout
    user_ids = params[:user_ids]
    
    if user_ids.blank?
      render json: { success: false, message: 'No users selected.' }, status: 400
      return
    end
    
    sessions = UserSession.active.where(user_id: user_ids)
    count = 0
    
    sessions.each do |session|
      if session.update(active: false, ended_at: Time.current)
        SessionLog.log_action(session, 'admin_bulk_force_logout', request)
        count += 1
        
        # Send notification to user
        Jobs.enqueue(:session_notification, 
          user_id: session.user_id,
          action: 'admin_bulk_force_logout',
          session_id: session.session_id
        )
      end
    end
    
    render json: { 
      success: true, 
      message: "Terminated #{count} sessions successfully.",
      terminated_count: count
    }
  end
  
  def statistics
    @statistics = UserSession.session_statistics
    
    # Additional statistics
    @statistics.merge!({
      inactive_users: UserSession.expired.active.count,
      recent_logins: SessionLog.by_action('login').recent.count,
      recent_logouts: SessionLog.by_action('logout').recent.count,
      force_logouts: SessionLog.by_action('force_logout').recent.count,
      inactivity_warnings: SessionLog.by_action('inactivity_warning').recent.count
    })
    
    render json: @statistics
  end
  
  def cleanup_expired
    before_count = UserSession.active.count
    UserSession.cleanup_expired_sessions
    after_count = UserSession.active.count
    cleaned_count = before_count - after_count
    
    render json: {
      success: true,
      message: "Cleaned up #{cleaned_count} expired sessions.",
      cleaned_count: cleaned_count
    }
  end
end 