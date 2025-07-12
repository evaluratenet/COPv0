class CommunityStatistics
  include ActiveModel::Model
  
  def self.total_members
    User.where(approved: true).count
  end
  
  def self.weekly_active_users
    User.joins(:user_sessions)
        .where('user_sessions.created_at >= ?', 1.week.ago)
        .distinct
        .count
  end
  
  def self.peer_connections_initiated
    # Count contact requests sent
    ContactRequest.count
  end
  
  def self.contributing_members_percentage
    total = User.where(approved: true).count
    return 0 if total == 0
    
    contributing = User.joins(:posts)
                      .where(approved: true)
                      .where('posts.created_at >= ?', 30.days.ago)
                      .distinct
                      .count
    
    ((contributing.to_f / total) * 100).round
  end
  
  def self.discussions_by_category
    categories = {
      'Strategy' => 142,
      'HR & Leadership' => 97,
      'Finance & Risk' => 86,
      'Sales & Growth' => 73,
      'M&A and Restructuring' => 29
    }
    
    # In a real implementation, this would query actual discussion counts
    # For now, using the provided numbers
    categories
  end
  
  def self.members_by_level
    levels = {
      'GM Level' => 0,
      'MD Level' => 0,
      'VP Level' => 0,
      'C-Level' => 0
    }
    
    # Query users by their title/level
    User.where(approved: true).find_each do |user|
      title = user.custom_fields['job_title']&.downcase || ''
      
      case title
      when /ceo|chief executive|president/
        levels['C-Level'] += 1
      when /vp|vice president/
        levels['VP Level'] += 1
      when /md|managing director/
        levels['MD Level'] += 1
      when /gm|general manager/
        levels['GM Level'] += 1
      else
        # Default to C-Level for other executive titles
        levels['C-Level'] += 1 if title.match?(/chief|director|head of|executive/)
      end
    end
    
    levels
  end
  
  def self.all_statistics
    {
      total_members: total_members,
      weekly_active_users: weekly_active_users,
      peer_connections_initiated: peer_connections_initiated,
      contributing_members_percentage: contributing_members_percentage,
      members_by_level: members_by_level,
      discussions_by_category: discussions_by_category
    }
  end
  
  # Cache statistics for performance
  def self.cached_statistics
    Rails.cache.fetch('community_statistics', expires_in: 1.hour) do
      all_statistics
    end
  end
  
  # Force refresh of cached statistics
  def self.refresh_statistics
    Rails.cache.delete('community_statistics')
    cached_statistics
  end
end 