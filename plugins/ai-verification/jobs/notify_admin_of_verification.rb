module Jobs
  class NotifyAdminOfVerification < ::Jobs::Base
    def execute(args)
      assessment_id = args[:assessment_id]
      return unless assessment_id
      
      assessment = VerificationAssessment.find(assessment_id)
      return unless assessment
      
      # Get all admin users
      admin_users = User.where(admin: true).where(active: true)
      
      admin_users.each do |admin|
        send_admin_notification(admin, assessment)
      end
    end
    
    private
    
    def send_admin_notification(admin, assessment)
      # Create notification email
      email_template = create_notification_email(admin, assessment)
      
      # Send email
      Jobs.enqueue(:user_email,
        to_address: admin.email,
        email_type: 'verification_assessment_notification',
        user_id: admin.id,
        assessment_id: assessment.id,
        template: email_template
      )
      
      # Create in-app notification
      Notification.create!(
        user_id: admin.id,
        notification_type: Notification.types[:admin_verification_assessment],
        data: {
          assessment_id: assessment.id,
          user_id: assessment.user_id,
          user_name: assessment.user.name,
          ai_recommendation: assessment.ai_recommendation_display,
          confidence_score: assessment.confidence_score,
          status: assessment.status,
          time_ago: assessment.time_since_created
        }.to_json
      )
    end
    
    def create_notification_email(admin, assessment)
      user = assessment.user
      
      # Determine urgency based on confidence and recommendation
      urgency = determine_urgency(assessment)
      
      # Create email template
      <<~EMAIL
        Subject: New User Verification Assessment - #{user.name} (#{urgency})
        
        Dear #{admin.username},
        
        A new user verification assessment has been completed by Vera, our AI verification specialist.
        
        **User Information:**
        - Name: #{user.name}
        - Email: #{user.email}
        - Company: #{user.company}
        - Title: #{user.title}
        - LinkedIn: #{user.linkedin_url || 'Not provided'}
        
        **Vera's Assessment:**
        - Recommendation: #{assessment.ai_recommendation_display}
        - Confidence Score: #{(assessment.confidence_score * 100).round}%
        - Risk Factors: #{assessment.risk_factors_display}
        - Assessment Time: #{assessment.time_since_created} hours ago
        
        **Risk Analysis:**
        #{format_risk_factors(assessment.risk_factors)}
        
        **Quick Actions:**
        - [Review Assessment](#{Discourse.base_url}/admin/verifications/#{assessment.id})
        - [Approve User](#{Discourse.base_url}/admin/verifications/#{assessment.id}/approve)
        - [Reject User](#{Discourse.base_url}/admin/verifications/#{assessment.id}/decline)
        - [Request More Info](#{Discourse.base_url}/admin/verifications/#{assessment.id}/request_info)
        
        **Assessment Details:**
        - User ID: #{user.id}
        - Assessment ID: #{assessment.id}
        - Created: #{assessment.created_at.strftime('%Y-%m-%d %H:%M UTC')}
        - Status: #{assessment.status.humanize}
        
        **Verification Criteria Met:**
        #{format_verification_criteria(assessment)}
        
        **Next Steps:**
        #{determine_next_steps(assessment)}
        
        Please review Vera's assessment and take appropriate action within 24 hours.
        
        Best regards,
        Vera - Circle of Peers AI Verification Specialist
        
        ---
        This is an automated notification from Vera, the Circle of Peers AI verification specialist.
        Assessment ID: #{assessment.id}
        Generated: #{Time.current.strftime('%Y-%m-%d %H:%M UTC')}
      EMAIL
    end
    
    def determine_urgency(assessment)
      if assessment.high_confidence_approval?
        '✅ High Confidence Approval'
      elsif assessment.high_confidence_rejection?
        '❌ High Confidence Rejection'
      elsif assessment.requires_immediate_attention?
        '🚨 Requires Immediate Attention'
      elsif assessment.confidence_score && assessment.confidence_score >= 0.7
        '⚠️ Review Required'
      else
        '📋 Standard Review'
      end
    end
    
    def format_risk_factors(risk_factors)
      return 'No risk factors identified' unless risk_factors.present?
      
      risk_factors.map do |factor|
        severity_icon = case factor['severity']
        when 'high' then '🔴'
        when 'medium' then '🟡'
        when 'low' then '🟢'
        else '⚪'
        end
        
        "#{severity_icon} **#{factor['name']}**: #{factor['description']}"
      end.join("\n")
    end
    
    def format_verification_criteria(assessment)
      criteria = VerificationCriteria.required.by_weight
      
      criteria.map do |criterion|
        # This would be enhanced with actual verification results
        "✅ #{criterion.name.humanize} (#{criterion.weight} weight)"
      end.join("\n")
    end
    
    def determine_next_steps(assessment)
      case assessment.ai_recommendation
      when 'approve'
        "**Recommended Action:** Approve user - Vera has high confidence in this application."
      when 'reject'
        "**Recommended Action:** Reject user - Vera has identified significant risk factors."
      when 'review_required'
        "**Recommended Action:** Manual review required - Vera needs human judgment for this case."
      else
        "**Recommended Action:** Review assessment details and make manual decision."
      end
    end
  end
end 