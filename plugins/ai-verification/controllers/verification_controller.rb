class Admin::VerificationController < Admin::AdminController
  before_action :ensure_admin
  before_action :set_assessment, only: [:show, :approve, :decline, :request_info]
  
  def index
    @assessments = VerificationAssessment.includes(:user, :reviewed_by)
                                       .order(created_at: :desc)
                                       .page(params[:page])
                                       .per(20)
    
    # Filter by status
    @assessments = @assessments.where(status: params[:status]) if params[:status].present?
    
    # Filter by confidence score
    if params[:confidence_min].present?
      @assessments = @assessments.where('confidence_score >= ?', params[:confidence_min])
    end
    
    # Filter by time
    if params[:time_filter].present?
      case params[:time_filter]
      when 'today'
        @assessments = @assessments.where('created_at >= ?', 1.day.ago)
      when 'week'
        @assessments = @assessments.where('created_at >= ?', 1.week.ago)
      when 'month'
        @assessments = @assessments.where('created_at >= ?', 1.month.ago)
      end
    end
    
    # Statistics
    @stats = {
      total: VerificationAssessment.count,
      pending: VerificationAssessment.pending.count,
      approved: VerificationAssessment.approved.count,
      rejected: VerificationAssessment.rejected.count,
      needs_info: VerificationAssessment.needs_info.count,
      high_confidence: VerificationAssessment.by_confidence(0.8).count,
      avg_confidence: VerificationAssessment.where.not(confidence_score: nil).average(:confidence_score)&.round(2)
    }
    
    render_serialized(@assessments, AdminVerificationSerializer)
  end
  
  def show
    render_serialized(@assessment, AdminVerificationSerializer)
  end
  
  def approve
    begin
      @assessment.approve!(current_user, params[:admin_notes])
      
      # Log the action
      StaffActionLogger.new(current_user).log_verification_approved(@assessment)
      
      render json: { 
        success: true, 
        message: "User approved successfully. Peer ID will be assigned automatically." 
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
  
  def decline
    begin
      reason = params[:reason] || 'Application did not meet platform requirements'
      @assessment.reject!(current_user, reason, params[:admin_notes])
      
      # Log the action
      StaffActionLogger.new(current_user).log_verification_rejected(@assessment)
      
      render json: { 
        success: true, 
        message: "User rejected successfully. Rejection notification sent." 
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
  
  def request_info
    begin
      requested_info = params[:requested_info] || 'Additional information required'
      @assessment.request_info!(current_user, requested_info, params[:admin_notes])
      
      # Log the action
      StaffActionLogger.new(current_user).log_verification_info_requested(@assessment)
      
      render json: { 
        success: true, 
        message: "Information request sent to user successfully." 
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
  
  def bulk_actions
    action = params[:action]
    assessment_ids = params[:assessment_ids]
    
    unless assessment_ids.present? && action.present?
      render json: { error: 'Missing required parameters' }, status: :bad_request
      return
    end
    
    assessments = VerificationAssessment.where(id: assessment_ids)
    success_count = 0
    error_count = 0
    
    assessments.each do |assessment|
      begin
        case action
        when 'approve'
          assessment.approve!(current_user)
          success_count += 1
        when 'reject'
          assessment.reject!(current_user, 'Bulk rejection')
          success_count += 1
        when 'request_info'
          assessment.request_info!(current_user, 'Additional information required')
          success_count += 1
        else
          error_count += 1
        end
      rescue => e
        error_count += 1
        Rails.logger.error "Bulk action error for assessment #{assessment.id}: #{e.message}"
      end
    end
    
    render json: { 
      success: true, 
      message: "Bulk action completed. #{success_count} successful, #{error_count} failed." 
    }
  end
  
  def statistics
    # Time-based statistics
    time_stats = {
      today: VerificationAssessment.where('created_at >= ?', 1.day.ago).count,
      week: VerificationAssessment.where('created_at >= ?', 1.week.ago).count,
      month: VerificationAssessment.where('created_at >= ?', 1.month.ago).count
    }
    
    # Status distribution
    status_stats = {
      pending: VerificationAssessment.pending.count,
      approved: VerificationAssessment.approved.count,
      rejected: VerificationAssessment.rejected.count,
      needs_info: VerificationAssessment.needs_info.count
    }
    
    # Confidence score distribution
    confidence_stats = {
      high: VerificationAssessment.by_confidence(0.8).count,
      medium: VerificationAssessment.where('confidence_score >= ? AND confidence_score < ?', 0.5, 0.8).count,
      low: VerificationAssessment.where('confidence_score < ?', 0.5).count,
      none: VerificationAssessment.where(confidence_score: nil).count
    }
    
    # Average processing time
    avg_processing_time = VerificationAssessment.where.not(reviewed_at: nil)
                                              .where.not(created_at: nil)
                                              .average("EXTRACT(EPOCH FROM (reviewed_at - created_at)) / 3600")
                                              &.round(1)
    
    render json: {
      time_stats: time_stats,
      status_stats: status_stats,
      confidence_stats: confidence_stats,
      avg_processing_time_hours: avg_processing_time
    }
  end
  
  private
  
  def set_assessment
    @assessment = VerificationAssessment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Assessment not found' }, status: :not_found
  end
end 