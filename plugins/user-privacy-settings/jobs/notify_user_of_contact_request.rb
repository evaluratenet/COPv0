module Jobs
  class NotifyUserOfContactRequest < ::Jobs::Base
    def execute(args)
      request_id = args[:request_id]
      action = args[:action]
      reason = args[:reason]
      
      request = ContactRequest.find(request_id)
      return unless request
      
      case action
      when 'new_request'
        notify_target_user_of_new_request(request)
      when 'approved'
        notify_requester_of_approval(request)
        notify_target_user_of_approval(request)
      when 'rejected'
        notify_requester_of_rejection(request, reason)
        notify_target_user_of_rejection(request, reason)
      end
    end
    
    private
    
    def notify_target_user_of_new_request(request)
      email_template = create_new_request_email(request)
      
      Jobs.enqueue(:user_email,
        to_address: request.target_user.email,
        email_type: 'contact_request_new',
        user_id: request.target_user.id,
        template: email_template
      )
      
      # Create in-app notification
      Notification.create!(
        user_id: request.target_user.id,
        notification_type: Notification.types[:contact_request],
        data: {
          request_id: request.id,
          requester_id: request.requester.id,
          requester_name: request.requester.name,
          message: request.message,
          action: 'new_request'
        }.to_json
      )
    end
    
    def notify_requester_of_approval(request)
      email_template = create_approval_email(request, 'requester')
      
      Jobs.enqueue(:user_email,
        to_address: request.requester.email,
        email_type: 'contact_request_approved',
        user_id: request.requester.id,
        template: email_template
      )
    end
    
    def notify_target_user_of_approval(request)
      email_template = create_approval_email(request, 'target')
      
      Jobs.enqueue(:user_email,
        to_address: request.target_user.email,
        email_type: 'contact_request_approved',
        user_id: request.target_user.id,
        template: email_template
      )
    end
    
    def notify_requester_of_rejection(request, reason)
      email_template = create_rejection_email(request, 'requester', reason)
      
      Jobs.enqueue(:user_email,
        to_address: request.requester.email,
        email_type: 'contact_request_rejected',
        user_id: request.requester.id,
        template: email_template
      )
    end
    
    def notify_target_user_of_rejection(request, reason)
      email_template = create_rejection_email(request, 'target', reason)
      
      Jobs.enqueue(:user_email,
        to_address: request.target_user.email,
        email_type: 'contact_request_rejected',
        user_id: request.target_user.id,
        template: email_template
      )
    end
    
    def create_new_request_email(request)
      <<~EMAIL
        Subject: New Contact Request - Circle of Peers
        
        Dear #{request.target_user.name},
        
        You have received a new contact request from another Circle of Peers member.
        
        **Requester Information:**
        - Name: #{request.requester.name}
        - Company: #{request.requester.company || 'Not specified'}
        - Title: #{request.requester.title || 'Not specified'}
        
        **Message:**
        #{request.message || 'No message provided'}
        
        **Request Details:**
        - Request ID: #{request.id}
        - Date: #{request.created_at.strftime('%Y-%m-%d %H:%M UTC')}
        
        **Next Steps:**
        You can approve or reject this request through your privacy settings:
        #{Discourse.base_url}/my/privacy-settings
        
        **Privacy Reminder:**
        You control who can contact you. You can change your contact preferences at any time.
        
        Best regards,
        Circle of Peers Team
      EMAIL
    end
    
    def create_approval_email(request, recipient_type)
      if recipient_type == 'requester'
        <<~EMAIL
          Subject: Contact Request Approved - Circle of Peers
          
          Dear #{request.requester.name},
          
          Your contact request to #{request.target_user.name} has been approved.
          
          **Contact Information:**
          - Name: #{request.target_user.name}
          - Email: #{request.target_user.email}
          - Company: #{request.target_user.company || 'Not specified'}
          - Title: #{request.target_user.title || 'Not specified'}
          
          **Request Details:**
          - Request ID: #{request.id}
          - Approved: #{request.approved_at.strftime('%Y-%m-%d %H:%M UTC')}
          
          You can now reach out to this member directly.
          
          Best regards,
          Circle of Peers Team
        EMAIL
      else
        <<~EMAIL
          Subject: Contact Request Approved - Circle of Peers
          
          Dear #{request.target_user.name},
          
          You have approved a contact request from #{request.requester.name}.
          
          **Requester Information:**
          - Name: #{request.requester.name}
          - Email: #{request.requester.email}
          - Company: #{request.requester.company || 'Not specified'}
          - Title: #{request.requester.title || 'Not specified'}
          
          **Request Details:**
          - Request ID: #{request.id}
          - Approved: #{request.approved_at.strftime('%Y-%m-%d %H:%M UTC')}
          
          This member can now contact you directly.
          
          Best regards,
          Circle of Peers Team
        EMAIL
      end
    end
    
    def create_rejection_email(request, recipient_type, reason)
      if recipient_type == 'requester'
        <<~EMAIL
          Subject: Contact Request Rejected - Circle of Peers
          
          Dear #{request.requester.name},
          
          Your contact request to #{request.target_user.name} has been rejected.
          
          **Request Details:**
          - Request ID: #{request.id}
          - Rejected: #{request.rejected_at.strftime('%Y-%m-%d %H:%M UTC')}
          - Reason: #{reason || 'No reason provided'}
          
          **Next Steps:**
          You can send contact requests to other members who have enabled contact requests in their privacy settings.
          
          Best regards,
          Circle of Peers Team
        EMAIL
      else
        <<~EMAIL
          Subject: Contact Request Rejected - Circle of Peers
          
          Dear #{request.target_user.name},
          
          You have rejected a contact request from #{request.requester.name}.
          
          **Request Details:**
          - Request ID: #{request.id}
          - Rejected: #{request.rejected_at.strftime('%Y-%m-%d %H:%M UTC')}
          - Reason: #{reason || 'No reason provided'}
          
          The requester has been notified of your decision.
          
          Best regards,
          Circle of Peers Team
        EMAIL
      end
    end
  end
end 