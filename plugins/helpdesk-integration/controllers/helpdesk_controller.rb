class HelpdeskController < ApplicationController
  before_action :ensure_logged_in, except: [:index, :knowledge_base, :show_article]
  before_action :ensure_admin, only: [:admin_dashboard, :admin_tickets, :admin_kb]
  before_action :set_ticket, only: [:show_ticket]
  before_action :set_article, only: [:show_article]
  
  def index
    @popular_articles = KnowledgeArticle.popular_articles(5)
    @recent_articles = KnowledgeArticle.recent_articles(5)
    @categories = KnowledgeArticle.categories
    
    if current_user
      @user_tickets = current_user.support_tickets.recent.limit(3)
      @open_tickets_count = current_user.support_tickets.open.count
    end
    
    render layout: 'application'
  end
  
  def tickets
    @tickets = current_user.support_tickets
                          .includes(:assigned_to)
                          .order(created_at: :desc)
                          .page(params[:page])
                          .per(10)
    
    render layout: 'application'
  end
  
  def new_ticket
    @ticket = SupportTicket.new
    @categories = SupportTicket.categories
    @priorities = SupportTicket.priorities
    
    render layout: 'application'
  end
  
  def create_ticket
    @ticket = SupportTicket.create_for_user(
      current_user,
      params[:subject],
      params[:description],
      params[:category] || 'general',
      params[:priority] || 'medium'
    )
    
    if @ticket.persisted?
      # Send confirmation email
      Jobs.enqueue(:ticket_created_notification, ticket_id: @ticket.id)
      
      redirect_to support_ticket_path(@ticket), notice: 'Support ticket created successfully.'
    else
      @categories = SupportTicket.categories
      @priorities = SupportTicket.priorities
      render :new_ticket, layout: 'application'
    end
  end
  
  def show_ticket
    unless current_user.admin? || @ticket.user_id == current_user.id
      redirect_to support_path, alert: 'Access denied.'
      return
    end
    
    render layout: 'application'
  end
  
  def knowledge_base
    @query = params[:q]
    @category = params[:category]
    
    if @query.present?
      @articles = KnowledgeArticle.search_articles(@query, 20)
    elsif @category.present?
      @articles = KnowledgeArticle.articles_by_category(@category, 20)
    else
      @articles = KnowledgeArticle.published.recent.limit(20)
    end
    
    @categories = KnowledgeArticle.categories
    @popular_articles = KnowledgeArticle.popular_articles(5)
    
    render layout: 'application'
  end
  
  def show_article
    @article.increment_view_count!
    @related_articles = @article.related_articles
    
    render layout: 'application'
  end
  
  # Admin methods
  def admin_dashboard
    @stats = {
      total_tickets: SupportTicket.count,
      open_tickets: SupportTicket.open.count,
      urgent_tickets: SupportTicket.urgent.count,
      resolved_today: SupportTicket.where('resolved_at >= ?', 1.day.ago).count,
      total_articles: KnowledgeArticle.count,
      published_articles: KnowledgeArticle.published.count
    }
    
    @recent_tickets = SupportTicket.includes(:user, :assigned_to)
                                  .recent
                                  .limit(10)
    
    @urgent_tickets = SupportTicket.includes(:user, :assigned_to)
                                  .urgent
                                  .limit(5)
    
    render layout: 'application'
  end
  
  def admin_tickets
    @tickets = SupportTicket.includes(:user, :assigned_to)
                          .order(created_at: :desc)
                          .page(params[:page])
                          .per(20)
    
    # Filter by status
    @tickets = @tickets.where(status: params[:status]) if params[:status].present?
    
    # Filter by category
    @tickets = @tickets.where(category: params[:category]) if params[:category].present?
    
    # Filter by priority
    @tickets = @tickets.where(priority: params[:priority]) if params[:priority].present?
    
    @categories = SupportTicket.categories
    @priorities = SupportTicket.priorities
    @statuses = SupportTicket.statuses
    
    render layout: 'application'
  end
  
  def admin_kb
    @articles = KnowledgeArticle.includes(:created_by)
                               .order(created_at: :desc)
                               .page(params[:page])
                               .per(20)
    
    # Filter by category
    @articles = @articles.where(category: params[:category]) if params[:category].present?
    
    # Filter by published status
    if params[:published].present?
      @articles = @articles.where(published: params[:published] == 'true')
    end
    
    @categories = KnowledgeArticle.categories
    
    render layout: 'application'
  end
  
  def assign_ticket
    @ticket = SupportTicket.find(params[:ticket_id])
    @ticket.assign_to!(current_user)
    
    redirect_to admin_helpdesk_tickets_path, notice: 'Ticket assigned successfully.'
  end
  
  def resolve_ticket
    @ticket = SupportTicket.find(params[:ticket_id])
    @ticket.resolve!(current_user, params[:resolution_notes])
    
    redirect_to admin_helpdesk_tickets_path, notice: 'Ticket resolved successfully.'
  end
  
  def close_ticket
    @ticket = SupportTicket.find(params[:ticket_id])
    @ticket.close!(current_user)
    
    redirect_to admin_helpdesk_tickets_path, notice: 'Ticket closed successfully.'
  end
  
  def reopen_ticket
    @ticket = SupportTicket.find(params[:ticket_id])
    @ticket.reopen!
    
    redirect_to admin_helpdesk_tickets_path, notice: 'Ticket reopened successfully.'
  end
  
  private
  
  def set_ticket
    @ticket = SupportTicket.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to support_path, alert: 'Ticket not found.'
  end
  
  def set_article
    @article = KnowledgeArticle.find_by_slug_or_id(params[:id])
    redirect_to support_kb_path, alert: 'Article not found.' unless @article
  end
  
  def ticket_params
    params.require(:support_ticket).permit(:subject, :description, :category, :priority)
  end
  
  def article_params
    params.require(:knowledge_article).permit(:title, :content, :category, :tag_list, :published)
  end
end 