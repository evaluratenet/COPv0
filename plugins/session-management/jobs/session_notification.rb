module Jobs
  class SessionNotification < ::Jobs::Base
    sidekiq_options retry: 3
    
    def execute(args)
      user_id = args[:user_id]
      action = args[:action]
      session_id = args[:session_id]
      
      user = User.find(user_id)
      session = UserSession.find_by(session_id: session_id)
      
      return unless user && session
      
      case action
      when 'inactivity_warning'
        send_inactivity_warning(user, session)
      when 'inactivity_timeout'
        send_inactivity_timeout(user, session)
      when 'admin_force_logout'
        send_admin_force_logout(user, session)
      when 'force_logout_others'
        send_force_logout_others(user, session)
      end
    end
    
    private
    
    def send_inactivity_warning(user, session)
      email_opts = {
        to: user.email,
        subject: I18n.t('session.notifications.inactivity_warning.subject'),
        template: 'session_inactivity_warning',
        template_vars: {
          username: user.username,
          peer_id: user.custom_fields['peer_id'],
          last_activity: session.last_activity.strftime('%B %d, %Y at %I:%M %p'),
          login_url: "#{Discourse.base_url}/session/continue",
          timeout_minutes: 5
        }
      }
      
      Email::Sender.new(Email::Message.new(email_opts), :session_notification).send
    end
    
    def send_inactivity_timeout(user, session)
      email_opts = {
        to: user.email,
        subject: I18n.t('session.notifications.inactivity_timeout.subject'),
        template: 'session_inactivity_timeout',
        template_vars: {
          username: user.username,
          peer_id: user.custom_fields['peer_id'],
          last_activity: session.last_activity.strftime('%B %d, %Y at %I:%M %p'),
          login_url: "#{Discourse.base_url}/login",
          session_duration: format_duration(session.duration)
        }
      }
      
      Email::Sender.new(Email::Message.new(email_opts), :session_notification).send
    end
    
    def send_admin_force_logout(user, session)
      email_opts = {
        to: user.email,
        subject: I18n.t('session.notifications.admin_force_logout.subject'),
        template: 'session_admin_force_logout',
        template_vars: {
          username: user.username,
          peer_id: user.custom_fields['peer_id'],
          logout_time: Time.current.strftime('%B %d, %Y at %I:%M %p'),
          login_url: "#{Discourse.base_url}/login",
          contact_url: "#{Discourse.base_url}/contact"
        }
      }
      
      Email::Sender.new(Email::Message.new(email_opts), :session_notification).send
    end
    
    def send_force_logout_others(user, session)
      email_opts = {
        to: user.email,
        subject: I18n.t('session.notifications.force_logout_others.subject'),
        template: 'session_force_logout_others',
        template_vars: {
          username: user.username,
          peer_id: user.custom_fields['peer_id'],
          logout_time: Time.current.strftime('%B %d, %Y at %I:%M %p'),
          current_session_ip: session.ip_address,
          current_session_location: session.location_info
        }
      }
      
      Email::Sender.new(Email::Message.new(email_opts), :session_notification).send
    end
    
    def format_duration(seconds)
      return 'Unknown' unless seconds
      
      hours = (seconds / 3600).to_i
      minutes = ((seconds % 3600) / 60).to_i
      
      if hours > 0
        "#{hours} hour#{hours == 1 ? '' : 's'} and #{minutes} minute#{minutes == 1 ? '' : 's'}"
      else
        "#{minutes} minute#{minutes == 1 ? '' : 's'}"
      end
    end
  end
end 