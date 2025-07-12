module Jobs
  class NotifyAdminOfEmailChange < ::Jobs::Base
    def execute(args)
      request_id = args[:request_id]
      return unless request_id
      
      request = EmailChangeRequest.find(request_id)
      return unless request
      
      # Get all admin users
      admin_users = User.where(admin: true).where(active: true)
      
      admin_users.each do |admin|
        send_admin_notification(admin, request)
      end
    end
    
    private
    
    def send_admin_notification(admin, request)
      # Create notification email
      email_template = create_notification_email(admin, request)
      
      # Send email
      Jobs.enqueue(:user_email,
        to_address: admin.email,
        email_type: 'email_change_notification',
        user_id: admin.id,
        request_id: request.id,
        template: email_template
      )
      
      # Create in-app notification
      Notification.create!(
        user_id: admin.id,
        notification_type: Notification.types[:admin_email_change],
        data: {
          request_id: request.id,
          user_id: request.user_id,
          user_name: request.user.name,
          change_type: request.change_type,
          old_email: request.old_email,
          new_email: request.new_email,
          risk_assessment: request.risk_assessment,
          time_ago: request.time_since_created
        }.to_json
      )
    end
    
    def create_notification_email(admin, request)
      user = request.user
      
      # Determine urgency based on change type and risk
      urgency = determine_urgency(request)
      
      # Create email template
      <<~EMAIL
        Subject: Email Change Request - #{user.name} (#{urgency})
        
        Dear #{admin.username},
        
        A user has requested an email change that requires admin approval.
        
        **User Information:**
        - Name: #{user.name}
        - Peer ID: #{user.custom_fields['peer_id'] || 'N/A'}
        - Company: #{user.company}
        - Title: #{user.title}
        - Current Email: #{request.old_email}
        - Requested Email: #{request.new_email}
        
        **Change Details:**
        - Change Type: #{request.change_type.humanize}
        - Risk Assessment: #{request.risk_assessment.upcase}
        - Requires Admin Approval: #{request.requires_admin_approval ? 'Yes' : 'No'}
        - Requested: #{request.time_since_created} hours ago
        
        **Risk Analysis:**
        #{format_risk_analysis(request)}
        
        **User History:**
        - Member Since: #{user.created_at.strftime('%Y-%m-%d')}
        - Last Seen: #{user.last_seen_at&.strftime('%Y-%m-%d %H:%M') || 'Never'}
        - Trust Level: #{user.trust_level}
        - Post Count: #{user.post_count}
        
        **Quick Actions:**
        - [Review Request](#{Discourse.base_url}/admin/email-changes/#{request.id})
        - [Approve Change](#{Discourse.base_url}/admin/email-changes/#{request.id}/approve)
        - [Reject Change](#{Discourse.base_url}/admin/email-changes/#{request.id}/reject)
        
        **Request Details:**
        - Request ID: #{request.id}
        - Created: #{request.created_at.strftime('%Y-%m-%d %H:%M UTC')}
        - Status: #{request.status.humanize}
        
        **Next Steps:**
        #{determine_next_steps(request)}
        
        Best regards,
        Circle of Peers System
      EMAIL
    end
    
    def determine_urgency(request)
      case request.risk_assessment
      when 'high'
        'HIGH PRIORITY'
      when 'medium'
        'MEDIUM PRIORITY'
      else
        'LOW PRIORITY'
      end
    end
    
    def format_risk_analysis(request)
      case request.change_type
      when 'corporate_to_private'
        if request.user.has_corporate_email_backup?
          "🟡 MEDIUM RISK: User has corporate email backup on file"
        else
          "🔴 HIGH RISK: No corporate email backup, potential verification bypass"
        end
      when 'private_to_corporate'
        "🟢 LOW RISK: Upgrading to corporate email"
      else
        "🟡 MEDIUM RISK: Corporate to corporate change"
      end
    end
    
    def determine_next_steps(request)
      case request.change_type
      when 'corporate_to_private'
        if request.user.has_corporate_email_backup?
          "1. Review user's corporate email backup\n2. Consider approving if backup is valid\n3. Monitor for unusual activity"
        else
          "1. Review user's activity and history\n2. Consider requiring additional verification\n3. May need to request corporate email backup"
        end
      when 'private_to_corporate'
        "1. Verify the new corporate email domain\n2. Consider auto-approval if domain is legitimate\n3. Update user's verification status"
      else
        "1. Review the change for legitimacy\n2. Verify both email domains\n3. Consider user's activity patterns"
      end
    end
  end
end 