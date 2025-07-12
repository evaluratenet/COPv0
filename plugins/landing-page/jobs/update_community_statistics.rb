module Jobs
  class UpdateCommunityStatistics < ::Jobs::Base
    def execute(args)
      # Refresh community statistics
      CommunityStatistics.refresh_statistics
      
      # Log the update
      Rails.logger.info "Community statistics updated at #{Time.current}"
    end
  end
end 