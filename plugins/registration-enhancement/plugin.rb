# name: registration-enhancement
# about: Enhances user registration with referrer email field for Circle of Peers
# version: 1.0.0
# authors: Circle of Peers Team
# url: https://github.com/circleofpeers/discourse-registration-enhancement

register_asset 'stylesheets/registration-enhancement.scss'

enabled_site_setting :registration_enhancement_enabled

after_initialize do
  # Add referrer email field to registration form
  module ::RegistrationEnhancement
    class Engine < ::Rails::Engine
      engine_name "registration_enhancement"
      isolate_namespace RegistrationEnhancement
    end
  end
  
  # Override registration controller to handle referrer email
  UsersController.class_eval do
    before_action :validate_referrer_email, only: [:create]
    
    private
    
    def validate_referrer_email
      referrer_email = params[:user][:referrer_email]&.strip
      return if referrer_email.blank?
      
      # Store referrer email in session for later use
      session[:referrer_email] = referrer_email
    end
  end
  
  # Hook into user creation to capture referrer email
  on(:user_created) do |user|
    referrer_email = session[:referrer_email]
    if referrer_email.present?
      user.custom_fields['referrer_email'] = referrer_email.downcase
      user.save!
      
      # Clear session
      session.delete(:referrer_email)
    end
  end
  
  # Add referrer email field to user serializer
  add_to_serializer(:user, :referrer_email) do
    object.custom_fields['referrer_email']
  end
  
  # Add to application controller for validation
  ApplicationController.class_eval do
    def validate_referrer_email_format(email)
      return false if email.blank?
      email =~ URI::MailTo::EMAIL_REGEXP
    end
    
    def validate_referrer_exists(email)
      return false if email.blank?
      User.exists?(email: email.downcase)
    end
    
    def validate_referrer_subscription(email)
      return false if email.blank?
      referrer = User.find_by(email: email.downcase)
      return false unless referrer
      referrer.has_active_subscription?
    end
  end
end

# Add referrer email column to users table
class AddReferrerEmailToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :referrer_email, :string
    add_index :users, :referrer_email
  end
end 