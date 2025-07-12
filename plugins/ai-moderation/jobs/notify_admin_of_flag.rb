module Jobs
  class NotifyAdminOfFlag < ::Jobs::Base
    def execute(args)
      flag_id = args[:flag_id]
      return unless flag_id
      
      flag = PostFlag.find(flag_id)
      return unless flag
      
      # Get all admin users
      admin_users = User.where(admin: true).where(active: true)
      
      admin_users.each do |admin|
        send_admin_notification(admin, flag)
      end
    end
    
    private
    
    def send_admin_notification(admin, flag)
      # Create notification email
      email_template = create_notification_email(admin, flag)
      
      # Send email
      Jobs.enqueue(:user_email,
        to_address: admin.email,
        email_type: 'post_flag_notification',
        user_id: admin.id,
        flag_id: flag.id,
        template: email_template
      )
      
      # Create in-app notification
      Notification.create!(
        user_id: admin.id,
        notification_type: Notification.types[:admin_post_flag],
        data: {
          flag_id: flag.id,
          post_id: flag.post_id,
          violation_type: flag.violation_type.name,
          severity: flag.violation_type.severity,
          flagged_by: flag.flagged_by_peer_display,
          time_ago: flag.time_since_flagged
        }.to_json
      )
    end
    
    def create_notification_email(admin, flag)
      severity_label = flag.violation_type.severity_label
      urgency = flag.requires_immediate_attention? ? 'URGENT' : 'Standard'
      
      <<~EMAIL
        #{urgency} - Post Flagged for Violation
        
        A post has been flagged for violating platform terms.
        
        **Flag Details:**
        - Post ID: #{flag.post_id}
        - Violation: #{flag.violation_type.name} (#{severity_label})
        - Flagged by: #{flag.flagged_by_peer_display}
        - Time: #{flag.created_at.strftime('%Y-%m-%d %H:%M UTC')}
        - Reason: #{flag.reason}
        
        **Post Content:**
        #{flag.post.raw.truncate(500)}
        
        **Action Required:**
        - Review the flagged post
        - Determine appropriate action
        - Update flag status in admin panel
        
        **Quick Actions:**
        - View in Admin Panel: #{Discourse.base_url}/admin/flags/#{flag.id}
        - Approve Flag: #{Discourse.base_url}/admin/flags/#{flag.id}/approve
        - Reject Flag: #{Discourse.base_url}/admin/flags/#{flag.id}/reject
        
        This is an automated notification from the Circle of Peers moderation system.
        
        Best regards,
        Circle of Peers Admin System
      EMAIL
    end
  end
end 