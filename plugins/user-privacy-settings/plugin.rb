# name: user-privacy-settings
# about: User privacy controls for Circle of Peers - profile visibility and contactability
# version: 1.0.0
# authors: Circle of Peers Team
# url: https://github.com/circleofpeers/discourse-user-privacy-settings

enabled_site_setting :user_privacy_settings_enabled

after_initialize do
  # Load the plugin's models and controllers
  load File.expand_path('../models/user_privacy_setting.rb', __FILE__)
  load File.expand_path('../controllers/privacy_settings_controller.rb', __FILE__)
  load File.expand_path('../jobs/notify_user_of_contact_request.rb', __FILE__)
  
  # Add routes
  Discourse::Application.routes.append do
    get '/my/privacy-settings' => 'privacy_settings#show'
    post '/my/privacy-settings/update' => 'privacy_settings#update'
    post '/users/:username/contact-request' => 'privacy_settings#submit_contact_request'
    get '/admin/contact-requests' => 'privacy_settings#admin_contact_requests'
    post '/admin/contact-requests/:id/approve' => 'privacy_settings#admin_approve_contact'
    post '/admin/contact-requests/:id/reject' => 'privacy_settings#admin_reject_contact'
  end
  
  # Add admin panel
  add_admin_route 'contact_requests.title', 'contact_requests'
  
  # Add to user serializer
  add_to_serializer(:user, :privacy_settings) do
    settings = UserPrivacySetting.find_by(user_id: object.id)
    if settings
      {
        profile_visible: settings.profile_visible,
        contactable: settings.contactable,
        show_name: settings.show_name,
        show_company: settings.show_company,
        show_title: settings.show_title,
        show_email: settings.show_email
      }
    else
      {
        profile_visible: false,
        contactable: false,
        show_name: false,
        show_company: false,
        show_title: false,
        show_email: false
      }
    end
  end
  
  add_to_serializer(:user, :can_contact) do
    return false unless scope&.user
    return false unless object.contactable_by?(scope.user)
    return false unless scope.user.has_active_subscription?
    true
  end
  
  add_to_serializer(:user, :show_contact_option) do
    return false unless scope&.user
    return false unless object.contactable_by?(scope.user)
    return false unless scope.user.has_active_subscription?
    true
  end
  
  # Override user profile visibility
  User.class_eval do
    def profile_visible_to?(viewer)
      return true if viewer&.id == id
      return true if viewer&.admin?
      
      privacy_settings = UserPrivacySetting.find_by(user_id: id)
      privacy_settings&.profile_visible || false
    end
    
    def contactable_by?(viewer)
      return false if viewer&.id == id # Can't contact yourself
      return true if viewer&.admin?
      
      privacy_settings = UserPrivacySetting.find_by(user_id: id)
      privacy_settings&.contactable || false
    end
    
    def has_active_subscription?
      # Check if user has an active subscription or is in trial period
      subscription = Subscription.find_by(user_id: id)
      return false unless subscription
      
      subscription.status == 'active' || subscription.status == 'trial'
    end
    
    def show_profile_field_to?(viewer, field)
      return true if viewer&.id == id
      return true if viewer&.admin?
      
      privacy_settings = UserPrivacySetting.find_by(user_id: id)
      return false unless privacy_settings&.profile_visible
      
      case field
      when :name
        privacy_settings.show_name
      when :company
        privacy_settings.show_company
      when :title
        privacy_settings.show_title
      when :email
        privacy_settings.show_email
      else
        false
      end
    end
  end
  
  # Override user serializer to respect privacy settings
  add_to_serializer(:user, :name) do
    if object.show_profile_field_to?(scope&.user, :name)
      object.name
    else
      nil
    end
  end
  
  add_to_serializer(:user, :company) do
    if object.show_profile_field_to?(scope&.user, :company)
      object.company
    else
      nil
    end
  end
  
  add_to_serializer(:user, :title) do
    if object.show_profile_field_to?(scope&.user, :title)
      object.title
    else
      nil
    end
  end
  
  add_to_serializer(:user, :email) do
    if object.show_profile_field_to?(scope&.user, :email)
      object.email
    else
      nil
    end
  end
  
  # Hook into user creation to create default privacy settings
  on(:user_created) do |user|
    UserPrivacySetting.create_for_user(user)
  end
end 