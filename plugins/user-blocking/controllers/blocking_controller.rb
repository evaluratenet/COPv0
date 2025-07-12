class BlockingController < ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_admin, only: [:admin_index, :admin_remove_block]
  
  def index
    @user = current_user
    @blocked_users = @user.get_blocked_users
    @blocked_by_users = @user.get_blocked_by_users
  end
  
  def block_user
    target_username = params[:username]
    reason = params[:reason]&.strip
    
    target_user = User.find_by(username: target_username)
    unless target_user
      flash[:error] = "User not found."
      redirect_to request.referer || '/'
      return
    end
    
    # Prevent self-blocking
    if target_user.id == current_user.id
      flash[:error] = "You cannot block yourself."
      redirect_to request.referer || '/'
      return
    end
    
    begin
      block = UserBlock.create_block(current_user, target_user, reason)
      
      flash[:notice] = "User blocked successfully."
    rescue => e
      flash[:error] = e.message
    end
    
    redirect_to request.referer || '/'
  end
  
  def unblock_user
    target_username = params[:username]
    
    target_user = User.find_by(username: target_username)
    unless target_user
      flash[:error] = "User not found."
      redirect_to request.referer || '/'
      return
    end
    
    if current_user.unblock_user(target_user)
      flash[:notice] = "User unblocked successfully."
    else
      flash[:error] = "User was not blocked."
    end
    
    redirect_to request.referer || '/'
  end
  
  # Admin actions
  def admin_index
    @blocks = UserBlock.includes(:blocker, :blocked_user)
                      .order(created_at: :desc)
                      .page(params[:page])
                      .per(20)
  end
  
  def admin_remove_block
    @block = UserBlock.find(params[:id])
    
    unless @block.can_be_removed_by?(current_user)
      flash[:error] = "You cannot remove this block."
      redirect_to admin_user_blocks_path
      return
    end
    
    @block.deactivate!
    flash[:notice] = "User block removed."
    redirect_to admin_user_blocks_path
  end
  
  private
  
  def admin_user_blocks_path
    '/admin/user-blocks'
  end
end 