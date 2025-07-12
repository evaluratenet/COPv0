class KnowledgeArticle < ActiveRecord::Base
  belongs_to :created_by, class_name: 'User'
  
  validates :title, presence: true
  validates :content, presence: true
  validates :category, inclusion: { in: %w[getting_started billing technical moderation platform_features troubleshooting] }
  validates :published, inclusion: { in: [true, false] }
  
  scope :published, -> { where(published: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :popular, -> { order(view_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :search, ->(query) { where("title ILIKE ? OR content ILIKE ?", "%#{query}%", "%#{query}%") }
  
  before_create :generate_slug
  after_create :create_helpdeskz_article
  after_update :update_helpdeskz_article, if: :saved_change_to_content?
  
  def self.categories
    {
      'getting_started' => 'Getting Started',
      'billing' => 'Billing & Payments',
      'technical' => 'Technical Support',
      'moderation' => 'Content Moderation',
      'platform_features' => 'Platform Features',
      'troubleshooting' => 'Troubleshooting'
    }
  end
  
  def self.search_articles(query, limit = 10)
    published.search(query).limit(limit)
  end
  
  def self.popular_articles(limit = 5)
    published.popular.limit(limit)
  end
  
  def self.recent_articles(limit = 5)
    published.recent.limit(limit)
  end
  
  def self.articles_by_category(category, limit = 10)
    published.by_category(category).recent.limit(limit)
  end
  
  def increment_view_count!
    increment!(:view_count)
  end
  
  def generate_slug
    return if slug.present?
    
    base_slug = title.parameterize
    counter = 1
    
    while KnowledgeArticle.where(slug: base_slug).exists?
      base_slug = "#{title.parameterize}-#{counter}"
      counter += 1
    end
    
    self.slug = base_slug
  end
  
  def category_display
    self.class.categories[category] || category.humanize
  end
  
  def excerpt(length = 150)
    content.truncate(length, separator: ' ')
  end
  
  def reading_time
    # Estimate reading time: ~200 words per minute
    word_count = content.split.size
    minutes = (word_count / 200.0).ceil
    "#{minutes} min read"
  end
  
  def related_articles(limit = 3)
    KnowledgeArticle.published
                   .by_category(category)
                   .where.not(id: id)
                   .recent
                   .limit(limit)
  end
  
  def tag_list
    tags.join(', ')
  end
  
  def tag_list=(tag_string)
    self.tags = tag_string.split(',').map(&:strip).reject(&:blank?)
  end
  
  def has_tags?
    tags.any?
  end
  
  def to_param
    slug
  end
  
  def self.find_by_slug_or_id(identifier)
    if identifier.match?(/\A\d+\z/)
      find(identifier)
    else
      find_by(slug: identifier)
    end
  end
  
  private
  
  def create_helpdeskz_article
    # Create article in HelpdeskZ system
    Jobs.enqueue(:create_helpdeskz_article, article_id: id)
  end
  
  def update_helpdeskz_article
    # Update article in HelpdeskZ system
    Jobs.enqueue(:update_helpdeskz_article, article_id: id)
  end
end 