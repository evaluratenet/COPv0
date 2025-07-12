# Admin Interface Integration
# Adds billing management to Discourse admin panel

after_initialize do
  # Add admin menu item
  add_admin_route 'billing.title', 'billing'
  
  # Add to admin menu
  Admin::DashboardController.class_eval do
    def billing
      @subscriptions = Subscription.includes(:user, :payment_methods, :billing_events)
                                  .order(created_at: :desc)
                                  .page(params[:page])
      
      @statistics = Subscription.billing_statistics
      
      respond_to do |format|
        format.html { render 'admin/billing/index' }
        format.json { render json: @subscriptions }
      end
    end
  end
  
  # Add billing statistics to admin dashboard
  Admin::DashboardController.class_eval do
    def billing_statistics
      @statistics = Subscription.billing_statistics
      
      # Additional statistics
      @statistics.merge!({
        revenue_this_month: calculate_monthly_revenue,
        revenue_this_year: calculate_yearly_revenue,
        average_subscription_value: calculate_average_subscription_value,
        churn_rate: calculate_churn_rate,
        trial_conversion_rate: calculate_trial_conversion_rate
      })
      
      render json: @statistics
    end
    
    private
    
    def calculate_monthly_revenue
      Subscription.active
                  .where('current_period_start >= ?', 1.month.ago)
                  .sum(:amount) / 100.0
    end
    
    def calculate_yearly_revenue
      Subscription.active
                  .where('current_period_start >= ?', 1.year.ago)
                  .sum(:amount) / 100.0
    end
    
    def calculate_average_subscription_value
      active_subs = Subscription.active
      return 0 if active_subs.count == 0
      
      active_subs.sum(:amount) / 100.0 / active_subs.count
    end
    
    def calculate_churn_rate
      total_subs = Subscription.count
      return 0 if total_subs == 0
      
      canceled_subs = Subscription.canceled.where('canceled_at >= ?', 1.month.ago).count
      (canceled_subs.to_f / total_subs * 100).round(2)
    end
    
    def calculate_trial_conversion_rate
      trial_subs = Subscription.trial.count
      return 0 if trial_subs == 0
      
      converted_subs = Subscription.where(status: 'active').where('trial_end < ?', Time.current).count
      (converted_subs.to_f / trial_subs * 100).round(2)
    end
  end
end 