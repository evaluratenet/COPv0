# Admin Interface Integration
# Adds session management to Discourse admin panel

after_initialize do
  # Add admin menu item
  Admin::DashboardController.class_eval do
    def sessions
      @sessions = UserSession.active.includes(:user, :session_logs)
                             .order(created_at: :desc)
                             .page(params[:page])
      
      @statistics = UserSession.session_statistics
      
      respond_to do |format|
        format.html { render 'admin/sessions/index' }
        format.json { render json: @sessions }
      end
    end
  end
  
  # Add admin route
  Discourse::Application.routes.append do
    namespace :admin, constraints: StaffConstraint.new do
      resources :sessions, only: [:index, :show, :destroy] do
        member do
          post :force_logout
        end
        collection do
          post :bulk_force_logout
          get :statistics
          post :cleanup_expired
        end
      end
    end
  end
  
  # Add admin menu
  Admin::AdminController.class_eval do
    def sessions
      @sessions = UserSession.active.includes(:user, :session_logs)
                             .order(created_at: :desc)
                             .page(params[:page])
      
      @statistics = UserSession.session_statistics
      
      respond_to do |format|
        format.html { render 'admin/sessions/index' }
        format.json { render json: @sessions }
      end
    end
  end
  
  # Add admin menu item
  add_admin_route 'session_management.title', 'sessions'
  
  # Add to admin menu
  Admin::DashboardController.class_eval do
    def sessions
      @sessions = UserSession.active.includes(:user, :session_logs)
                             .order(created_at: :desc)
                             .page(params[:page])
      
      @statistics = UserSession.session_statistics
      
      respond_to do |format|
        format.html { render 'admin/sessions/index' }
        format.json { render json: @sessions }
      end
    end
  end
end 