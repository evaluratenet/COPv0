# name: ai-verification
# about: AI-assisted user verification for Circle of Peers registration
# version: 1.0.0
# authors: Circle of Peers Team
# url: https://github.com/circleofpeers/discourse-ai-verification

register_asset 'stylesheets/ai-verification.scss'

enabled_site_setting :ai_verification_enabled

after_initialize do
  # Load the plugin's models and controllers
  load File.expand_path('../models/verification_assessment.rb', __FILE__)
  load File.expand_path('../models/verification_criteria.rb', __FILE__)
  load File.expand_path('../controllers/verification_controller.rb', __FILE__)
  load File.expand_path('../jobs/process_ai_verification.rb', __FILE__)
  load File.expand_path('../jobs/notify_admin_of_verification.rb', __FILE__)
  
  # Add routes
  Discourse::Application.routes.append do
    get '/admin/verifications' => 'verification#index'
    get '/admin/verifications/:id' => 'verification#show'
    post '/admin/verifications/:id/approve' => 'verification#approve'
    post '/admin/verifications/:id/decline' => 'verification#decline'
    post '/admin/verifications/:id/request_info' => 'verification#request_info'
  end
  
  # Add admin panel
  add_admin_route 'verifications.title', 'verifications'
  
  # Hook into user registration
  on(:user_created) do |user|
    # Create verification assessment record
    VerificationAssessment.create_for_user(user)
    
    # Process AI verification in background
    Jobs.enqueue(:process_ai_verification, user_id: user.id)
  end
  
  # Hook into user approval
  on(:user_approved) do |user|
    assessment = VerificationAssessment.find_by(user_id: user.id)
    if assessment
      assessment.update!(status: 'approved', approved_at: Time.current)
    end
  end
  
  # Hook into user rejection
  on(:user_rejected) do |user|
    assessment = VerificationAssessment.find_by(user_id: user.id)
    if assessment
      assessment.update!(status: 'rejected', rejected_at: Time.current)
    end
  end
  
  # Add to user serializer
  add_to_serializer(:user, :verification_status) do
    assessment = VerificationAssessment.find_by(user_id: object.id)
    assessment&.status || 'pending'
  end
  
  # Add to user serializer
  add_to_serializer(:user, :verification_assessment) do
    assessment = VerificationAssessment.find_by(user_id: object.id)
    if assessment
      {
        status: assessment.status,
        ai_recommendation: assessment.ai_recommendation,
        confidence_score: assessment.confidence_score,
        risk_factors: assessment.risk_factors,
        created_at: assessment.created_at
      }
    else
      nil
    end
  end
  
  # Override registration form
  module ::AiVerification
    class Engine < ::Rails::Engine
      engine_name "ai_verification"
      isolate_namespace AiVerification
    end
  end
  
  # Add to application controller
  ApplicationController.class_eval do
    before_action :check_verification_status, if: :current_user
    
    private
    
    def check_verification_status
      return if controller_name == 'sessions'
      return if controller_name == 'users' && action_name == 'create'
      return if current_user.admin?
      
      assessment = VerificationAssessment.find_by(user_id: current_user.id)
      if assessment&.status == 'pending'
        # User is still pending verification
        redirect_to '/verification/pending'
      elsif assessment&.status == 'rejected'
        # User was rejected
        redirect_to '/verification/rejected'
      end
    end
  end
end

# Database migration
class CreateVerificationAssessments < ActiveRecord::Migration[7.0]
  def change
    create_table :verification_assessments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, default: 'pending'
      t.text :ai_recommendation
      t.decimal :confidence_score, precision: 3, scale: 2
      t.json :risk_factors
      t.json :verification_data
      t.text :admin_notes
      t.references :reviewed_by, null: true, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.datetime :approved_at
      t.datetime :rejected_at
      t.timestamps
    end
    
    add_index :verification_assessments, :status
    add_index :verification_assessments, :confidence_score
  end
end

class CreateVerificationCriteria < ActiveRecord::Migration[7.0]
  def change
    create_table :verification_criteria do |t|
      t.string :name, null: false
      t.text :description
      t.integer :weight, default: 1
      t.boolean :required, default: false
      t.json :ai_prompts
      t.timestamps
    end
    
    add_index :verification_criteria, :name, unique: true
  end
end 