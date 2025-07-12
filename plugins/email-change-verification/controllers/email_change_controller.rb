class EmailChangeController < ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_admin, only: [:admin_index, :admin_show, :admin_approve, :admin_reject]
  
  def request_form
    @user = current_user
    @pending_request = EmailChangeRequest.find_by(user_id: @user.id, status: 'pending')
  end
  
  def submit_request
    @user = current_user
    new_email = params[:new_email]&.strip
    
    unless new_email.present? && valid_email?(new_email)
      flash[:error] = "Please provide a valid email address."
      redirect_to '/email-change/request'
      return
    end
    
    if new_email.downcase == @user.email.downcase
      flash[:error] = "The new email must be different from your current email."
      redirect_to '/email-change/request'
      return
    end
    
    # Check if email is already in use
    if User.exists?(email: new_email.downcase)
      flash[:error] = "This email address is already registered."
      redirect_to '/email-change/request'
      return
    end
    
    # Create email change request
    request = EmailChangeRequest.create_for_user(@user, new_email)
    
    if request.requires_admin_approval
      # Notify admins of request requiring approval
      Jobs.enqueue(:notify_admin_of_email_change, request_id: request.id)
      flash[:notice] = "Your email change request has been submitted and is pending admin approval."
    else
      # Auto-approve simple changes
      request.approve!(current_user)
      flash[:notice] = "Your email has been successfully updated."
    end
    
    redirect_to '/my/preferences'
  end
  
  def verify_new_email
    token = params[:token]
    request = EmailChangeRequest.find_by(verification_token: token, status: 'pending')
    
    unless request
      flash[:error] = "Invalid or expired verification link."
      redirect_to '/my/preferences'
      return
    end
    
    # Mark as verified
    request.update!(verified_at: Time.current)
    
    # If auto-approvable, approve immediately
    if request.can_auto_approve?
      request.approve!(request.user)
      flash[:notice] = "Your email has been successfully verified and updated."
    else
      flash[:notice] = "Your email has been verified and is pending admin approval."
    end
    
    redirect_to '/my/preferences'
  end
  
  # Admin actions
  def admin_index
    @requests = EmailChangeRequest.includes(:user)
                                .order(created_at: :desc)
                                .page(params[:page])
                                .per(20)
  end
  
  def admin_show
    @request = EmailChangeRequest.includes(:user, :approved_by, :rejected_by)
                               .find(params[:id])
  end
  
  def admin_approve
    @request = EmailChangeRequest.find(params[:id])
    
    unless @request.status == 'pending'
      flash[:error] = "This request has already been processed."
      redirect_to admin_email_changes_path
      return
    end
    
    @request.approve!(current_user)
    flash[:notice] = "Email change request approved."
    redirect_to admin_email_changes_path
  end
  
  def admin_reject
    @request = EmailChangeRequest.find(params[:id])
    reason = params[:reason]
    
    unless @request.status == 'pending'
      flash[:error] = "This request has already been processed."
      redirect_to admin_email_changes_path
      return
    end
    
    @request.reject!(current_user, reason)
    flash[:notice] = "Email change request rejected."
    redirect_to admin_email_changes_path
  end
  
  private
  
  def valid_email?(email)
    email =~ URI::MailTo::EMAIL_REGEXP
  end
  
  def admin_email_changes_path
    '/admin/email-changes'
  end
end 