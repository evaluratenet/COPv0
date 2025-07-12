# name: user-blocking
# about: User blocking system for Circle of Peers - allows users to block specific members
# version: 1.0.0
# authors: Circle of Peers Team
# url: https://github.com/circleofpeers/discourse-user-blocking

enabled_site_setting :user_blocking_enabled

after_initialize do
  # Load the plugin's models and controllers
  load File.expand_path('../models/user_block.rb', __FILE__)
  load File.expand_path('../controllers/blocking_controller.rb', __FILE__)
  load File.expand_path('../jobs/notify_user_of_block.rb', __FILE__)
  
  # Add routes
  Discourse::Application.routes.append do
    get '/my/blocked-users' => 'blocking#index'
    post '/users/:username/block' => 'blocking#block_user'
    post '/users/:username/unblock' => 'blocking#unblock_user'
    get '/admin/user-blocks' => 'blocking#admin_index'
    post '/admin/user-blocks/:id/remove' => 'blocking#admin_remove_block'
  end
  
  # Add admin panel
  add_admin_route 'user_blocks.title', 'user_blocks'
  
  # Add to user serializer
  add_to_serializer(:user, :blocked_users) do
    blocks = UserBlock.where(blocker_id: object.id, active: true)
    blocks.map { |block| block.blocked_user.username }
  end
  
  add_to_serializer(:user, :blocked_by_users) do
    blocks = UserBlock.where(blocked_user_id: object.id, active: true)
    blocks.map { |block| block.blocker.username }
  end
  
  # Override user interactions to respect blocks
  User.class_eval do
    def has_blocked?(other_user)
      return false unless other_user
      UserBlock.exists?(blocker_id: id, blocked_user_id: other_user.id, active: true)
    end
    
    def is_blocked_by?(other_user)
      return false unless other_user
      UserBlock.exists?(blocker_id: other_user.id, blocked_user_id: id, active: true)
    end
    
    def can_interact_with?(other_user)
      return false unless other_user
      return false if has_blocked?(other_user)
      return false if is_blocked_by?(other_user)
      true
    end
    
    def block_user(target_user, reason = nil)
      # Check if already blocked
      existing_block = UserBlock.find_by(blocker_id: id, blocked_user_id: target_user.id)
      
      if existing_block
        if existing_block.active?
          raise "User is already blocked"
        else
          # Reactivate existing block
          existing_block.update!(active: true, reason: reason, blocked_at: Time.current)
          return existing_block
        end
      end
      
      # Create new block
      UserBlock.create!(
        blocker_id: id,
        blocked_user_id: target_user.id,
        reason: reason,
        active: true
      )
    end
    
    def unblock_user(target_user)
      block = UserBlock.find_by(blocker_id: id, blocked_user_id: target_user.id, active: true)
      return false unless block
      
      block.update!(active: false, unblocked_at: Time.current)
      true
    end
    
    def get_blocked_users
      UserBlock.where(blocker_id: id, active: true).includes(:blocked_user)
    end
    
    def get_blocked_by_users
      UserBlock.where(blocked_user_id: id, active: true).includes(:blocker)
    end
  end
  
  # Override post creation to prevent blocked users from interacting
  Post.class_eval do
    before_create :check_user_blocks
    
    private
    
    def check_user_blocks
      return unless user && topic&.user
      return if user.id == topic.user.id
      
      if !user.can_interact_with?(topic.user)
        errors.add(:base, "You cannot interact with this user due to blocking restrictions")
        throw(:abort)
      end
    end
  end
  
  # Override private message creation
  Topic.class_eval do
    before_create :check_private_message_blocks
    
    private
    
    def check_private_message_blocks
      return unless category_id == SiteSetting.private_message_category_id
      return unless user && allowed_users.any?
      
      allowed_users.each do |allowed_user|
        unless user.can_interact_with?(allowed_user)
          errors.add(:base, "You cannot send private messages to this user due to blocking restrictions")
          throw(:abort)
        end
      end
    end
  end
  
  # Override contact request creation
  ContactRequest.class_eval do
    before_create :check_contact_request_blocks
    
    private
    
    def check_contact_request_blocks
      unless requester.can_interact_with?(target_user)
        errors.add(:base, "You cannot send contact requests to this user due to blocking restrictions")
        throw(:abort)
      end
    end
  end
  
  # Filter blocked users from user lists
  User.class_eval do
    def self.visible_to(viewer)
      return all unless viewer
      
      blocked_user_ids = UserBlock.where(blocker_id: viewer.id, active: true).pluck(:blocked_user_id)
      blocked_by_user_ids = UserBlock.where(blocked_user_id: viewer.id, active: true).pluck(:blocker_id)
      
      excluded_ids = blocked_user_ids + blocked_by_user_ids
      
      where.not(id: excluded_ids)
    end
  end
  
  # Hook into user creation to initialize blocking capabilities
  on(:user_created) do |user|
    # User blocking is automatically available to all users
    Rails.logger.info "User #{user.username} can now use blocking features"
  end
end 