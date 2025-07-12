# name: landing-page
# about: Landing page for Circle of Peers platform
# version: 1.0.0
# authors: Circle of Peers Team
# url: https://github.com/circleofpeers/discourse-landing-page

register_asset 'stylesheets/landing-page.scss'
register_asset 'javascripts/landing-page.js'

enabled_site_setting :landing_page_enabled

after_initialize do
  # Load the plugin's models, controllers, and jobs
  load File.expand_path('../models/community_statistics.rb', __FILE__)
  load File.expand_path('../controllers/landing_controller.rb', __FILE__)
  load File.expand_path('../jobs/update_community_statistics.rb', __FILE__)
  
  # Add routes
  Discourse::Application.routes.append do
    get '/' => 'landing#index'
    get '/about' => 'landing#about'
    get '/features' => 'landing#features'
    get '/pricing' => 'landing#pricing'
    get '/contact' => 'landing#contact'
    post '/landing/refresh-statistics' => 'landing#refresh_statistics'
  end
  
  # Override Discourse's default home page for non-logged-in users
  on(:before_application_route) do |request|
    if request.path == '/' && !current_user
      # Redirect to landing page for non-logged-in users
      return redirect_to '/landing'
    end
  end
  
  # Add to application controller
  ApplicationController.class_eval do
    def landing_page?
      request.path == '/' && !current_user
    end
  end
  
  # Hook into user events to refresh statistics
  on(:user_approved) do |user|
    # Refresh statistics when a new user is approved
    Jobs.enqueue(:update_community_statistics)
  end
  
  on(:post_created) do |post|
    # Refresh statistics when new content is created
    Jobs.enqueue(:update_community_statistics)
  end
  
  on(:contact_request_created) do |request|
    # Refresh statistics when new connections are made
    Jobs.enqueue(:update_community_statistics)
  end
  
  # Schedule periodic statistics updates
  module ::Jobs
    class ScheduleCommunityStatisticsUpdate < ::Jobs::Base
      def execute(args)
        # Schedule the next update in 1 hour
        Jobs.enqueue(:update_community_statistics, {})
        Jobs.enqueue(:schedule_community_statistics_update, {}, run_at: 1.hour.from_now)
      end
    end
  end
  
  # Start the periodic update schedule if not already running
  unless Jobs.scheduled_jobs.any? { |job| job[:job] == :schedule_community_statistics_update }
    Jobs.enqueue(:schedule_community_statistics_update, {}, run_at: 1.hour.from_now)
  end
end 