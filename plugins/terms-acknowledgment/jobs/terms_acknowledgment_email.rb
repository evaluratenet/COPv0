module Jobs
  class TermsAcknowledgmentEmail < ::Jobs::Base
    def execute(args)
      user_id = args[:user_id]
      return unless user_id
      
      user = User.find(user_id)
      return unless user
      
      acknowledgment = TermsAcknowledgment.find_by(user_id: user_id)
      return unless acknowledgment&.acknowledged?
      
      send_acknowledgment_email(user, acknowledgment)
    end
    
    private
    
    def send_acknowledgment_email(user, acknowledgment)
      email_template = create_acknowledgment_email(user, acknowledgment)
      
      Jobs.enqueue(:user_email,
        to_address: user.email,
        email_type: 'terms_acknowledgment',
        user_id: user.id,
        template: email_template
      )
    end
    
    def create_acknowledgment_email(user, acknowledgment)
      <<~EMAIL
        Terms and Conditions Acknowledgment Confirmation
        
        Dear #{user.username},
        
        Thank you for acknowledging the Circle of Peers Terms and Conditions.
        
        **Acknowledgment Details:**
        - Date: #{acknowledgment.acknowledged_at.strftime('%Y-%m-%d %H:%M UTC')}
        - Terms Version: #{acknowledgment.terms_version}
        - IP Address: #{acknowledgment.ip_address}
        
        **Important Reminders:**
        
        ✅ **No Solicitation**: Promoting products, services, or business opportunities is strictly prohibited
        ✅ **No Personal Data Sharing**: Revealing personal contact information is not allowed
        ✅ **No Harassment**: Hostile or inappropriate behavior will result in immediate suspension
        ✅ **No Confidential Information**: Sharing company secrets is prohibited
        ✅ **Immediate Suspension**: Violation of these terms will result in immediate account suspension
        
        **Your Account Status:**
        - Peer ID: #{user.custom_fields['peer_id'] || 'Pending Assignment'}
        - Subscription: 30-day free trial active
        - Access: Full platform access granted
        
        **Next Steps:**
        1. Complete your profile verification (if pending)
        2. Explore the conference rooms
        3. Start your first discussion
        4. Read the community guidelines
        
        **Support:**
        If you have any questions about the terms or platform usage, please contact us at admin@circleofpeers.net
        
        **Terms and Conditions:**
        You can review the full terms at any time at: #{Discourse.base_url}/terms
        
        Best regards,
        The Circle of Peers Team
        
        ---
        This email confirms your acknowledgment of the Circle of Peers Terms and Conditions on #{acknowledgment.acknowledged_at.strftime('%Y-%m-%d')}.
      EMAIL
    end
  end
end 