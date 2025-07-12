module Jobs
  class CreateHelpdeskzTicket < ::Jobs::Base
    def execute(args)
      ticket_id = args[:ticket_id]
      return unless ticket_id
      
      ticket = SupportTicket.find(ticket_id)
      return unless ticket
      
      # Create ticket in HelpdeskZ system
      helpdeskz_ticket_id = create_helpdeskz_ticket(ticket)
      
      if helpdeskz_ticket_id
        ticket.update!(helpdeskz_ticket_id: helpdeskz_ticket_id)
        Rails.logger.info "Created HelpdeskZ ticket #{helpdeskz_ticket_id} for ticket #{ticket.ticket_number}"
      else
        Rails.logger.error "Failed to create HelpdeskZ ticket for ticket #{ticket.ticket_number}"
      end
    end
    
    private
    
    def create_helpdeskz_ticket(ticket)
      # HelpdeskZ API configuration
      helpdeskz_url = ENV['HELPDESKZ_URL'] || 'https://helpdeskz.yourdomain.com'
      api_key = ENV['HELPDESKZ_API_KEY']
      
      return nil unless api_key.present?
      
      begin
        # Prepare ticket data for HelpdeskZ
        ticket_data = {
          subject: ticket.subject,
          message: ticket.description,
          email: ticket.user.email,
          name: ticket.user.name || ticket.user.username,
          department: map_category_to_department(ticket.category),
          priority: map_priority_to_helpdeskz(ticket.priority),
          custom_fields: {
            ticket_number: ticket.ticket_number,
            user_id: ticket.user.id,
            peer_id: ticket.user.custom_fields['peer_id'],
            category: ticket.category,
            source: 'circle_of_peers'
          }
        }
        
        # Make API call to HelpdeskZ
        response = HTTParty.post(
          "#{helpdeskz_url}/api/v1/tickets",
          body: ticket_data.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{api_key}",
            'Accept' => 'application/json'
          },
          timeout: 30
        )
        
        if response.success?
          result = JSON.parse(response.body)
          result['ticket_id'] || result['id']
        else
          Rails.logger.error "HelpdeskZ API error: #{response.code} - #{response.body}"
          nil
        end
        
      rescue => e
        Rails.logger.error "HelpdeskZ API connection error: #{e.message}"
        nil
      end
    end
    
    def map_category_to_department(category)
      department_mapping = {
        'general' => 'General Support',
        'billing' => 'Billing',
        'technical' => 'Technical Support',
        'moderation' => 'Content Moderation',
        'verification' => 'Account Verification',
        'account' => 'Account Management'
      }
      
      department_mapping[category] || 'General Support'
    end
    
    def map_priority_to_helpdeskz(priority)
      priority_mapping = {
        'low' => 1,
        'medium' => 2,
        'high' => 3,
        'urgent' => 4
      }
      
      priority_mapping[priority] || 2
    end
  end
  
  class UpdateHelpdeskzTicket < ::Jobs::Base
    def execute(args)
      ticket_id = args[:ticket_id]
      return unless ticket_id
      
      ticket = SupportTicket.find(ticket_id)
      return unless ticket&.helpdeskz_ticket_id
      
      # Update ticket in HelpdeskZ system
      success = update_helpdeskz_ticket(ticket)
      
      if success
        Rails.logger.info "Updated HelpdeskZ ticket #{ticket.helpdeskz_ticket_id} for ticket #{ticket.ticket_number}"
      else
        Rails.logger.error "Failed to update HelpdeskZ ticket for ticket #{ticket.ticket_number}"
      end
    end
    
    private
    
    def update_helpdeskz_ticket(ticket)
      helpdeskz_url = ENV['HELPDESKZ_URL'] || 'https://helpdeskz.yourdomain.com'
      api_key = ENV['HELPDESKZ_API_KEY']
      
      return false unless api_key.present?
      
      begin
        # Prepare update data
        update_data = {
          status: map_status_to_helpdeskz(ticket.status),
          assigned_to: ticket.assigned_to&.email,
          resolution: ticket.metadata&.dig('resolution_notes'),
          custom_fields: {
            status: ticket.status,
            assigned_to: ticket.assigned_to&.username,
            resolved_at: ticket.resolved_at&.iso8601
          }
        }
        
        # Make API call to HelpdeskZ
        response = HTTParty.put(
          "#{helpdeskz_url}/api/v1/tickets/#{ticket.helpdeskz_ticket_id}",
          body: update_data.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{api_key}",
            'Accept' => 'application/json'
          },
          timeout: 30
        )
        
        response.success?
        
      rescue => e
        Rails.logger.error "HelpdeskZ API update error: #{e.message}"
        false
      end
    end
    
    def map_status_to_helpdeskz(status)
      status_mapping = {
        'open' => 'open',
        'in_progress' => 'in_progress',
        'waiting_on_user' => 'waiting',
        'resolved' => 'resolved',
        'closed' => 'closed'
      }
      
      status_mapping[status] || 'open'
    end
  end
end 