module Jobs
  class ProcessAiModeration < ::Jobs::Base
    def execute(args)
      post_id = args[:post_id]
      return unless post_id
      
      post = Post.find(post_id)
      return unless post
      
      # Skip if post is already flagged
      return if post.flag_count > 0
      
      # Call AI service for moderation
      ai_result = call_ai_moderation_service(post)
      
      if ai_result && ai_result[:flagged]
        create_ai_flag(post, ai_result)
      end
    end
    
    private
    
    def call_ai_moderation_service(post)
      begin
        # Prepare request data
        request_data = {
          post_id: post.id,
          user_id: post.user_id,
          peer_id: post.user&.custom_fields&.dig('peer_id') || 'Unknown',
          content: post.raw,
          room_id: post.topic&.category_id,
          thread_id: post.topic_id
        }
        
        # Call FastAPI service
        response = HTTP.post(
          "#{ai_service_url}/moderate",
          json: request_data,
          headers: { 'Content-Type' => 'application/json' }
        )
        
        if response.status.success?
          JSON.parse(response.body.to_s, symbolize_names: true)
        else
          Rails.logger.error "AI moderation service error: #{response.status} - #{response.body}"
          nil
        end
        
      rescue => e
        Rails.logger.error "AI moderation service exception: #{e.message}"
        nil
      end
    end
    
    def create_ai_flag(post, ai_result)
      # Find violation type
      violation_type = ViolationType.find_by_name(ai_result[:violation_type])
      return unless violation_type
      
      # Create the flag
      PostFlag.create_ai_flag(
        post,
        violation_type,
        ai_result[:reason],
        ai_result[:confidence]
      )
      
      # Notify admin if high severity
      if violation_type.requires_immediate_action?
        Jobs.enqueue(:notify_admin_of_flag, flag_id: flag.id)
      end
    end
    
    def ai_service_url
      ENV['AI_SERVICE_URL'] || 'http://ai_service:8000'
    end
  end
end 