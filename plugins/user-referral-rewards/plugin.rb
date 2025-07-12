# name: user-referral-rewards
# about: User referral rewards system for Circle of Peers - tracks referrals and awards free months
# version: 1.0.0
# authors: Circle of Peers Team
# url: https://github.com/circleofpeers/discourse-user-referral-rewards

enabled_site_setting :user_referral_rewards_enabled

after_initialize do
  # Load the plugin's models and controllers
  load File.expand_path('../models/user_referral.rb', __FILE__)
  load File.expand_path('../models/referral_reward.rb', __FILE__)
  load File.expand_path('../controllers/referral_controller.rb', __FILE__)
  load File.expand_path('../jobs/process_referral_reward.rb', __FILE__)
  load File.expand_path('../jobs/notify_user_of_referral_reward.rb', __FILE__)
  
  # Add routes
  Discourse::Application.routes.append do
    get '/my/referrals' => 'referral#index'
    get '/admin/referrals' => 'referral#admin_index'
    get '/admin/referrals/:id' => 'referral#admin_show'
    post '/admin/referrals/:id/complete' => 'referral#admin_complete'
    post '/admin/referrals/:id/expire' => 'referral#admin_expire'
    get '/admin/referral-rewards' => 'referral#admin_rewards'
    post '/admin/referral-rewards/:id/apply' => 'referral#admin_apply_reward'
  end
  
  # Add admin panel
  add_admin_route 'referrals.title', 'referrals'
  
  # Hook into user registration to capture referrer email
  on(:user_created) do |user|
    # Check if user has referrer email in custom fields
    referrer_email = user.custom_fields['referrer_email']
    if referrer_email.present?
      # Create referral record
      UserReferral.create_referral(referrer_email, user)
    end
  end
  
  # Hook into user approval to activate referral
  on(:user_approved) do |user|
    referral = UserReferral.find_by(referred_user_id: user.id)
    if referral
      referral.activate!
    end
  end
  
  # Hook into subscription activation to complete referral
  on(:subscription_activated) do |subscription|
    user = subscription.user
    referral = UserReferral.find_by(referred_user_id: user.id, status: 'active')
    if referral
      referral.complete!
    end
  end
  
  # Add to user serializer
  add_to_serializer(:user, :referral_status) do
    referral = UserReferral.find_by(referred_user_id: object.id)
    referral ? referral.status : nil
  end
  
  add_to_serializer(:user, :referral_rewards) do
    rewards = ReferralReward.where(user_id: object.id)
    rewards.map do |reward|
      {
        id: reward.id,
        months_awarded: reward.months_awarded,
        status: reward.status,
        reason: reward.reason,
        created_at: reward.created_at,
        applied_at: reward.applied_at
      }
    end
  end
  
  # Override registration form to include referrer email field
  module ::UserReferralRewards
    class Engine < ::Rails::Engine
      engine_name "user_referral_rewards"
      isolate_namespace UserReferralRewards
    end
  end
  
  # Add referrer email field to user registration
  User.class_eval do
    before_create :capture_referrer_email
    
    private
    
    def capture_referrer_email
      # Store referrer email from registration params
      if respond_to?(:referrer_email) && referrer_email.present?
        self.custom_fields['referrer_email'] = referrer_email.downcase
      end
    end
  end
  
  # Add to application controller
  ApplicationController.class_eval do
    def validate_referrer_email(email)
      return false if email.blank?
      
      # Check if email is valid
      return false unless email =~ URI::MailTo::EMAIL_REGEXP
      
      # Check if referrer exists and is an active subscriber
      referrer = User.find_by(email: email.downcase)
      return false unless referrer
      
      # Check if referrer has active subscription
      return false unless referrer.has_active_subscription?
      
      true
    end
  end
end

# Database migration
class AddUserReferralTables < ActiveRecord::Migration[7.0]
  def change
    create_table :user_referrals do |t|
      t.references :referrer, null: false, foreign_key: { to_table: :users }
      t.references :referred_user, null: false, foreign_key: { to_table: :users }
      t.string :referrer_email, null: false
      t.string :status, default: 'pending'
      t.datetime :activated_at
      t.datetime :completed_at
      t.datetime :expired_at
      t.timestamps
    end
    
    add_index :user_referrals, :referred_user_id, unique: true
    add_index :user_referrals, :referrer_email
    add_index :user_referrals, :status
    
    create_table :referral_rewards do |t|
      t.references :user, null: false, foreign_key: true
      t.references :referral, null: false, foreign_key: { to_table: :user_referrals }
      t.integer :months_awarded, default: 1
      t.string :status, default: 'pending'
      t.text :reason
      t.datetime :applied_at
      t.datetime :expired_at
      t.timestamps
    end
    
    add_index :referral_rewards, :user_id
    add_index :referral_rewards, :status
  end
end