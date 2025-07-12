module Jobs
  class NotifyUserOfBlock < ::Jobs::Base
    def execute(args)
      block_id = args[:block_id]
      action = args[:action]
      
      block = UserBlock.find(block_id)
      return unless block
      
      case action
      when 'blocked'
        notify_blocked_user(block)
      when 'unblocked'
        notify_unblocked_user(block)
      end
    end
    
    private
    
    def notify_blocked_user(block)
      email_template = create_blocked_email(block)
      
      Jobs.enqueue(:user_email,
        to_address: block.blocked_user.email,
        email_type: 'user_blocked',
        user_id: block.blocked_user.id,
        template: email_template
      )
      
      # Create in-app notification
      Notification.create!(
        user_id: block.blocked_user.id,
        notification_type: Notification.types[:user_blocked],
        data: {
          block_id: block.id,
          blocker_id: block.blocker.id,
          blocker_name: block.blocker.name,
          reason: block.reason,
          action: 'blocked'
        }.to_json
      )
    end
    
    def notify_unblocked_user(block)
      email_template = create_unblocked_email(block)
      
      Jobs.enqueue(:user_email,
        to_address: block.blocked_user.email,
        email_type: 'user_unblocked',
        user_id: block.blocked_user.id,
        template: email_template
      )
      
      # Create in-app notification
      Notification.create!(
        user_id: block.blocked_user.id,
        notification_type: Notification.types[:user_unblocked],
        data: {
          block_id: block.id,
          blocker_id: block.blocker.id,
          blocker_name: block.blocker.name,
          action: 'unblocked'
        }.to_json
      )
    end
    
    def create_blocked_email(block)
      <<~EMAIL
        Subject: User Block Notification - Circle of Peers
        
        Dear #{block.blocked_user.name},
        
        You have been blocked by another Circle of Peers member.
        
        **Block Details:**
        - Blocked by: #{block.blocker.name}
        - Date: #{block.blocked_at.strftime('%Y-%m-%d %H:%M UTC')}
        - Reason: #{block.block_reason_display}
        
        **What this means:**
        - You cannot send posts, messages, or contact requests to this user
        - You cannot see their posts or profile
        - This user cannot interact with you either
        - The block is mutual and affects both users
        
        **Your options:**
        - Continue using the platform normally with other members
        - Contact support if you believe this block was made in error
        - The block can be removed by the user who created it or by administrators
        
        **Support:**
        If you have concerns about this block, contact support@circleofpeers.net
        
        Best regards,
        Circle of Peers Team
      EMAIL
    end
    
    def create_unblocked_email(block)
      <<~EMAIL
        Subject: User Block Removed - Circle of Peers
        
        Dear #{block.blocked_user.name},
        
        A user block has been removed, restoring normal interaction capabilities.
        
        **Block Details:**
        - Previously blocked by: #{block.blocker.name}
        - Block removed: #{block.unblocked_at.strftime('%Y-%m-%d %H:%M UTC')}
        - Original block date: #{block.blocked_at.strftime('%Y-%m-%d %H:%M UTC')}
        
        **What this means:**
        - You can now interact normally with this user
        - You can see their posts and profile again
        - You can send messages and contact requests
        - Normal platform functionality is restored
        
        **Privacy Reminder:**
        You can still control your privacy settings and contact preferences through your account settings.
        
        Best regards,
        Circle of Peers Team
      EMAIL
    end
  end
end 