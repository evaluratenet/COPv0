module Jobs
  class AssignPeerId < ::Jobs::Base
    def execute(args)
      user_id = args[:user_id]
      return unless user_id
      
      user = User.find(user_id)
      return unless user
      
      # Assign peer ID if not already assigned
      peer_id = PeerId.find_by(user_id: user_id)
      unless peer_id
        peer_id = PeerId.assign_to_user(user)
        
        # Send welcome email with peer ID
        send_welcome_email(user, peer_id)
      end
    end
    
    private
    
    def send_welcome_email(user, peer_id)
      # Create welcome email template
      email_template = <<~EMAIL
        Welcome to Circle of Peers!
        
        Your seat has been confirmed. You are now Peer #{peer_id.display_name}.
        
        Your anonymous identity will be used for all discussions. This ensures privacy while maintaining continuity in conversations.
        
        Next steps:
        1. Explore the conference rooms
        2. Read the community guidelines
        3. Start your first discussion
        
        Remember: Your seat is personal. Do not share access.
        
        Best regards,
        The Circle of Peers Team
      EMAIL
      
      # Send email (using Discourse's email system)
      Jobs.enqueue(:user_email,
        to_address: user.email,
        email_type: 'peer_id_welcome',
        user_id: user.id,
        template: email_template
      )
    end
  end
end 