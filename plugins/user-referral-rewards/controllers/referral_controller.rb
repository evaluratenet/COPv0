class ReferralController < ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_admin, only: [:admin_index, :admin_show, :admin_complete, :admin_expire, :admin_rewards, :admin_apply_reward]
  
  def index
    @user = current_user
    @referrals = UserReferral.where(referrer_id: @user.id).includes(:referred_user).order(created_at: :desc)
    @rewards = ReferralReward.where(user_id: @user.id).order(created_at: :desc)
  end
  
  # Admin actions
  def admin_index
    @referrals = UserReferral.includes(:referrer, :referred_user)
                            .order(created_at: :desc)
                            .page(params[:page])
                            .per(20)
  end
  
  def admin_show
    @referral = UserReferral.includes(:referrer, :referred_user).find(params[:id])
  end
  
  def admin_complete
    @referral = UserReferral.find(params[:id])
    
    if @referral.can_be_completed?
      @referral.complete!
      flash[:notice] = "Referral completed successfully. Referrer will receive 1 month free."
    else
      flash[:error] = "Referral cannot be completed. User must have an active subscription."
    end
    
    redirect_to admin_referral_path(@referral)
  end
  
  def admin_expire
    @referral = UserReferral.find(params[:id])
    
    if @referral.can_be_expired?
      @referral.expire!
      flash[:notice] = "Referral expired successfully."
    else
      flash[:error] = "Referral cannot be expired."
    end
    
    redirect_to admin_referral_path(@referral)
  end
  
  def admin_rewards
    @rewards = ReferralReward.includes(:user, :referral)
                            .order(created_at: :desc)
                            .page(params[:page])
                            .per(20)
  end
  
  def admin_apply_reward
    @reward = ReferralReward.find(params[:id])
    
    if @reward.can_be_applied?
      @reward.apply!
      flash[:notice] = "Reward applied successfully. User subscription extended by #{@reward.months_awarded} month(s)."
    else
      flash[:error] = "Reward cannot be applied. User must have an active subscription."
    end
    
    redirect_to admin_rewards_path
  end
  
  # API endpoints for AJAX calls
  def validate_referrer
    email = params[:email]&.strip
    
    if email.blank?
      render json: { valid: false, message: "Please enter a referrer email address." }
      return
    end
    
    unless email =~ URI::MailTo::EMAIL_REGEXP
      render json: { valid: false, message: "Please enter a valid email address." }
      return
    end
    
    referrer = User.find_by(email: email.downcase)
    unless referrer
      render json: { valid: false, message: "No user found with this email address." }
      return
    end
    
    unless referrer.has_active_subscription?
      render json: { valid: false, message: "This user does not have an active subscription." }
      return
    end
    
    render json: { 
      valid: true, 
      message: "Valid referrer found: #{referrer.username}",
      referrer_name: referrer.username
    }
  end
end 