module Jobs
  class UpdatePeerDisplay < ::Jobs::Base
    def execute(args)
      post_id = args[:post_id]
      return unless post_id
      
      post = Post.find(post_id)
      return unless post
      
      user = post.user
      return unless user
      
      # Get peer ID for the user
      peer_id = user.custom_fields['peer_id']
      return unless peer_id
      
      # Update the post to show peer ID instead of username
      # This is done by modifying the post's cooked content
      update_post_display(post, peer_id)
    end
    
    private
    
    def update_post_display(post, peer_id)
      # Store the peer ID in the post's custom fields
      post.custom_fields['display_peer_id'] = peer_id
      post.save!
      
      # Update the post's cooked content to show peer ID
      # This is a simplified approach - in practice, you'd want to
      # modify the post rendering template
      cooked_content = post.cooked
      
      # Replace username mentions with peer ID
      # This is a basic implementation - you'd want more sophisticated
      # username detection and replacement
      updated_content = cooked_content.gsub(
        /@#{post.user.username}/,
        "@#{peer_id}"
      )
      
      # Update the post if content changed
      if updated_content != cooked_content
        post.update!(cooked: updated_content)
      end
    end
  end
end 