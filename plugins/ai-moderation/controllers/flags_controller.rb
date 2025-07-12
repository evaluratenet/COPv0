class Admin::FlagsController < Admin::AdminController
  before_action :ensure_admin
  before_action :set_flag, only: [:show, :update, :destroy, :approve, :reject, :suspend_user]
  
  def index
    @flags = PostFlag.includes(:post, :violation_type, :flagged_by_user)
                    .order(created_at: :desc)
                    .page(params[:page])
                    .per(20)
    
    # Filter by status
    @flags = @flags.where(status: params[:status]) if params[:status].present?
    
    # Filter by source
    @flags = @flags.where(source: params[:source]) if params[:source].present?
    
    # Filter by violation type
    @flags = @flags.where(violation_type_id: params[:violation_type_id]) if params[:violation_type_id].present?
    
    # Filter by severity
    if params[:severity].present?
      violation_types = ViolationType.where('severity >= ?', params[:severity])
      @flags = @flags.where(violation_type_id: violation_types.pluck(:id))
    end
    
    render_serialized(@flags, AdminFlagSerializer)
  end
  
  def show
    render_serialized(@flag, AdminFlagSerializer)
  end
  
  def update
    if @flag.update(flag_params)
      render json: { success: true }
    else
      render json: { errors: @flag.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @flag.destroy
    render json: { success: true }
  end
  
  def approve
    begin
      @flag.approve!(current_user, params[:admin_notes])
      
      # Log the action
      StaffActionLogger.new(current_user).log_flag_approved(@flag)
      
      render json: { 
        success: true, 
        message: "Flag approved. Post has been #{@flag.violation_type.auto_hide_post? ? 'hidden' : 'flagged'}." 
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
  
  def reject
    begin
      @flag.reject!(current_user, params[:admin_notes])
      
      # Log the action
      StaffActionLogger.new(current_user).log_flag_rejected(@flag)
      
      render json: { success: true, message: "Flag rejected." }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
  
  def suspend_user
    begin
      @flag.suspend_user!(current_user, params[:admin_notes])
      
      # Log the action
      StaffActionLogger.new(current_user).log_user_suspended(@flag.post.user, @flag)
      
      render json: { 
        success: true, 
        message: "Flag approved and user suspended for 30 days." 
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
  
  def stats
    stats = {
      total_flags: PostFlag.count,
      pending_flags: PostFlag.pending.count,
      approved_flags: PostFlag.approved.count,
      rejected_flags: PostFlag.rejected.count,
      flags_by_source: PostFlag.group(:source).count,
      flags_by_violation_type: PostFlag.joins(:violation_type).group('violation_types.name').count,
      flags_by_severity: PostFlag.joins(:violation_type).group('violation_types.severity').count,
      recent_flags: PostFlag.recent.count,
      urgent_flags: PostFlag.joins(:violation_type).where('violation_types.severity >= ?', 4).pending.count
    }
    
    render json: stats
  end
  
  private
  
  def set_flag
    @flag = PostFlag.find(params[:id])
  end
  
  def flag_params
    params.require(:flag).permit(:status, :admin_notes)
  end
end

# Serializer for admin flag view
class AdminFlagSerializer < ApplicationSerializer
  attributes :id, :post_id, :flagged_by_peer_id, :violation_type, :reason, 
             :source, :status, :created_at, :reviewed_at, :admin_notes,
             :severity, :requires_immediate_attention, :time_since_flagged
  
  has_one :post, serializer: BasicPostSerializer
  has_one :flagged_by_user, serializer: BasicUserSerializer
  has_one :reviewed_by_admin, serializer: BasicUserSerializer
  
  def violation_type
    {
      id: object.violation_type.id,
      name: object.violation_type.name,
      description: object.violation_type.description,
      severity: object.violation_type.severity,
      severity_label: object.violation_type.severity_label,
      severity_color: object.violation_type.severity_color
    }
  end
  
  def severity
    object.violation_type.severity
  end
  
  def requires_immediate_attention
    object.requires_immediate_attention?
  end
  
  def time_since_flagged
    object.time_since_flagged
  end
end

# Basic post serializer for flag context
class BasicPostSerializer < ApplicationSerializer
  attributes :id, :raw, :cooked, :created_at, :updated_at, :user_id
  
  def raw
    object.raw.truncate(200)
  end
end

# Basic user serializer
class BasicUserSerializer < ApplicationSerializer
  attributes :id, :username, :peer_id
  
  def peer_id
    object.custom_fields['peer_id']
  end
end 