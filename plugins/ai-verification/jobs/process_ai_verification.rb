module Jobs
  class ProcessAiVerification < ::Jobs::Base
    def execute(args)
      user_id = args[:user_id]
      return unless user_id
      
      user = User.find(user_id)
      return unless user
      
      assessment = VerificationAssessment.find_by(user_id: user_id)
      return unless assessment
      
      # Process AI verification
      result = process_verification(user, assessment)
      
      # Update assessment with AI results
      assessment.update!(
        ai_recommendation: result[:recommendation],
        confidence_score: result[:confidence_score],
        risk_factors: result[:risk_factors]
      )
      
      # Notify admins of new assessment
      Jobs.enqueue(:notify_admin_of_verification, assessment_id: assessment.id)
      
      # Log the verification
      Rails.logger.info "Vera verification completed for user #{user_id}: #{result[:recommendation]} (#{(result[:confidence_score] * 100).round}% confidence)"
    end
    
    private
    
    def process_verification(user, assessment)
      # Prepare verification data
      verification_data = {
        user_info: {
          name: user.name,
          email: user.email,
          username: user.username,
          title: user.title,
          company: user.company,
          linkedin_url: user.linkedin_url,
          bio: user.bio,
          location: user.location,
          website: user.website
        },
        application_data: assessment.verification_data,
        criteria: load_verification_criteria
      }
      
      # Call AI service for verification
      ai_result = call_ai_verification_service(verification_data)
      
      # Process AI response
      process_ai_response(ai_result, verification_data)
    end
    
    def call_ai_verification_service(verification_data)
      # Call the FastAPI AI service
      ai_service_url = ENV['AI_SERVICE_URL'] || 'http://ai_service:8000'
      
      begin
        response = HTTParty.post(
          "#{ai_service_url}/verify",
          body: verification_data.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{ENV['AI_SERVICE_API_KEY']}"
          },
          timeout: 30
        )
        
        if response.success?
          JSON.parse(response.body)
        else
          Rails.logger.error "Vera verification service error: #{response.code} - #{response.body}"
          fallback_verification(verification_data)
        end
      rescue => e
        Rails.logger.error "Vera verification service connection error: #{e.message}"
        fallback_verification(verification_data)
      end
    end
    
    def process_ai_response(ai_result, verification_data)
      recommendation = ai_result['recommendation'] || 'review_required'
      confidence_score = ai_result['confidence_score'] || 0.5
      risk_factors = ai_result['risk_factors'] || []
      
      # Determine recommendation based on confidence and criteria
      final_recommendation = determine_final_recommendation(recommendation, confidence_score, risk_factors)
      
      {
        recommendation: final_recommendation,
        confidence_score: confidence_score,
        risk_factors: risk_factors,
        ai_analysis: ai_result['analysis'] || {}
      }
    end
    
    def determine_final_recommendation(ai_recommendation, confidence_score, risk_factors)
      # High confidence approvals
      if confidence_score >= 0.8 && ai_recommendation == 'approve'
        return 'approve'
      end
      
      # High confidence rejections
      if confidence_score >= 0.8 && ai_recommendation == 'reject'
        return 'reject'
      end
      
      # High risk factors
      high_risk_count = risk_factors.count { |rf| rf['severity'] == 'high' }
      if high_risk_count >= 2
        return 'reject'
      end
      
      # Medium confidence with some risk
      if confidence_score >= 0.6 && risk_factors.any?
        return 'review_required'
      end
      
      # Default to review required
      'review_required'
    end
    
    def fallback_verification(verification_data)
      # Fallback verification when Vera service is unavailable
      user_info = verification_data[:user_info]
      
      # Basic checks
      risk_factors = []
      confidence_score = 0.5
      
      # Check email domain
      if user_info[:email] && !corporate_email?(user_info[:email])
        risk_factors << {
          name: 'Personal Email',
          description: 'Using personal email instead of corporate email',
          severity: 'medium'
        }
        confidence_score -= 0.1
      end
      
      # Check LinkedIn URL
      if user_info[:linkedin_url].blank?
        risk_factors << {
          name: 'Missing LinkedIn',
          description: 'No LinkedIn profile provided',
          severity: 'high'
        }
        confidence_score -= 0.2
      end
      
      # Check job title
      if user_info[:title].blank?
        risk_factors << {
          name: 'Missing Title',
          description: 'No job title provided',
          severity: 'high'
        }
        confidence_score -= 0.2
      end
      
      # Check company
      if user_info[:company].blank?
        risk_factors << {
          name: 'Missing Company',
          description: 'No company information provided',
          severity: 'high'
        }
        confidence_score -= 0.2
      end
      
      # Determine recommendation
      recommendation = if confidence_score >= 0.7
        'approve'
      elsif confidence_score <= 0.3
        'reject'
      else
        'review_required'
      end
      
      {
        'recommendation' => recommendation,
        'confidence_score' => [confidence_score, 0.0].max,
        'risk_factors' => risk_factors,
        'analysis' => {
          'method' => 'fallback',
          'checks_performed' => ['email_domain', 'linkedin_presence', 'title_presence', 'company_presence'],
          'notes' => 'Fallback analysis performed due to Vera service unavailability'
        }
      }
    end
    
    def corporate_email?(email)
      return false if email.blank?
      
      personal_domains = [
        'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com',
        'aol.com', 'icloud.com', 'protonmail.com', 'mail.com'
      ]
      
      domain = email.split('@').last&.downcase
      !personal_domains.include?(domain)
    end
    
    def load_verification_criteria
      VerificationCriteria.all.map do |criteria|
        {
          name: criteria.name,
          description: criteria.description,
          weight: criteria.weight,
          required: criteria.required,
          ai_prompts: criteria.ai_prompts
        }
      end
    end
  end
end 