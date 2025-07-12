class PrivacySettingsController < ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_admin, only: [:admin_contact_requests, :admin_approve_contact, :admin_reject_contact]
  
  def show
    @user = current_user
    @privacy_settings = UserPrivacySetting.find_by(user_id: @user.id) || UserPrivacySetting.create_for_user(@user)
  end
  
  def update
    @user = current_user
    @privacy_settings = UserPrivacySetting.find_by(user_id: @user.id) || UserPrivacySetting.create_for_user(@user)
    
    if @privacy_settings.update_settings(params[:privacy_settings])
      flash[:notice] = "Privacy settings updated successfully."
    else
      flash[:error] = "Failed to update privacy settings."
    end
    
    redirect_to '/my/privacy-settings'
  end
  
  def submit_contact_request
    target_username = params[:username]
    message = params[:message]&.strip
    
    target_user = User.find_by(username: target_username)
    unless target_user
      flash[:error] = "User not found."
      redirect_to request.referer || '/'
      return
    end
    
    # Check if requester has active subscription
    unless current_user.has_active_subscription?
      flash[:error] = "Contact requests are only available to active subscribers."
      redirect_to request.referer || '/'
      return
    end
    
    # Check if target user is contactable
    unless target_user.contactable_by?(current_user)
      flash[:error] = "This user is not accepting contact requests."
      redirect_to request.referer || '/'
      return
    end
    
    begin
      request = ContactRequest.create_request(current_user, target_user, message)
      
      # Send notification to target user
      Jobs.enqueue(:notify_user_of_contact_request,
        request_id: request.id,
        action: 'new_request'
      )
      
      flash[:notice] = "Contact request sent successfully."
    rescue => e
      flash[:error] = e.message
    end
    
    redirect_to request.referer || '/'
  end
  
  # Admin actions
  def admin_contact_requests
    @requests = ContactRequest.includes(:requester, :target_user, :approved_by, :rejected_by)
                            .order(created_at: :desc)
                            .page(params[:page])
                            .per(20)
  end
  
  def admin_approve_contact
    @request = ContactRequest.find(params[:id])
    
    unless @request.status == 'pending'
      flash[:error] = "This request has already been processed."
      redirect_to admin_contact_requests_path
      return
    end
    
    @request.approve!(current_user)
    flash[:notice] = "Contact request approved."
    redirect_to admin_contact_requests_path
  end
  
  def admin_reject_contact
    @request = ContactRequest.find(params[:id])
    reason = params[:reason]
    
    unless @request.status == 'pending'
      flash[:error] = "This request has already been processed."
      redirect_to admin_contact_requests_path
      return
    end
    
    @request.reject!(current_user, reason)
    flash[:notice] = "Contact request rejected."
    redirect_to admin_contact_requests_path
  end
  
  private
  
  def admin_contact_requests_path
    '/admin/contact-requests'
  end
end 