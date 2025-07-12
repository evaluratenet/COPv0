# name: email-change-verification
# about: Handles email change verification for Circle of Peers users
# version: 1.0.0
# authors: Circle of Peers Team
# url: https://github.com/circleofpeers/discourse-email-change-verification

enabled_site_setting :email_change_verification_enabled

after_initialize do
  # Load the plugin's models and controllers
  load File.expand_path('../models/email_change_request.rb', __FILE__)
  load File.expand_path('../controllers/email_change_controller.rb', __FILE__)
  load File.expand_path('../jobs/process_email_change_verification.rb', __FILE__)
  load File.expand_path('../jobs/notify_admin_of_email_change.rb', __FILE__)
  
  # Add routes
  Discourse::Application.routes.append do
    get '/email-change/request' => 'email_change#request_form'
    post '/email-change/submit' => 'email_change#submit_request'
    get '/email-change/verify/:token' => 'email_change#verify_new_email'
    get '/admin/email-changes' => 'email_change#admin_index'
    get '/admin/email-changes/:id' => 'email_change#admin_show'
    post '/admin/email-changes/:id/approve' => 'email_change#admin_approve'
    post '/admin/email-changes/:id/reject' => 'email_change#admin_reject'
  end
  
  # Add admin panel
  add_admin_route 'email_changes.title', 'email_changes'
  
  # Hook into user email changes
  on(:user_updated) do |user|
    if user.saved_change_to_email?
      handle_email_change(user)
    end
  end
  
  # Add to user serializer
  add_to_serializer(:user, :email_change_status) do
    request = EmailChangeRequest.find_by(user_id: object.id, status: 'pending')
    request ? 'pending' : 'none'
  end
  
  # Override user update to require verification
  User.class_eval do
    before_update :check_email_change_requirements, if: :email_changed?
    
    private
    
    def check_email_change_requirements
      # If changing to private email, require additional verification
      if private_email?(email) && !has_corporate_email_backup?
        # Create email change request for admin review
        EmailChangeRequest.create!(
          user_id: id,
          old_email: email_was,
          new_email: email,
          change_type: 'corporate_to_private',
          status: 'pending',
          requires_admin_approval: true
        )
        
        # Revert email change until approved
        self.email = email_was
        throw(:abort)
      elsif corporate_email?(email) && private_email?(email_was)
        # Changing from private to corporate - simpler process
        EmailChangeRequest.create!(
          user_id: id,
          old_email: email_was,
          new_email: email,
          change_type: 'private_to_corporate',
          status: 'pending',
          requires_admin_approval: false
        )
      end
    end
    
    def private_email?(email)
      personal_domains = [
        'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com',
        'aol.com', 'icloud.com', 'protonmail.com', 'mail.com'
      ]
      domain = email.split('@').last&.downcase
      personal_domains.include?(domain)
    end
    
    def corporate_email?(email)
      !private_email?(email)
    end
    
    def has_corporate_email_backup?
      # Check if user has a secondary corporate email on file
      custom_fields['secondary_email'].present? && corporate_email?(custom_fields['secondary_email'])
    end
  end
end 