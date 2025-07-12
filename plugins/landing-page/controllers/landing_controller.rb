class LandingController < ApplicationController
  layout 'landing'
  
  def index
    @page_title = "Circle of Peers - Secure Peer Discussion for C-Level Executives"
    @meta_description = "A secure, high-trust platform built exclusively for C-level professionals who need a space to think out loud, seek perspective, and engage in honest peer dialogue."
    
    # Load dynamic community statistics
    @community_stats = CommunityStatistics.cached_statistics
    
    render 'landing/index'
  end
  
  def about
    @page_title = "About Circle of Peers"
    @meta_description = "Learn about Circle of Peers - why it exists, how it works, and what we stand for."
    
    render 'landing/about'
  end
  
  def features
    @page_title = "Features - Circle of Peers"
    @meta_description = "Discover the features that make Circle of Peers the premier platform for C-level executive discussions."
    
    render 'landing/features'
  end
  
  def pricing
    @page_title = "Pricing - Circle of Peers"
    @meta_description = "Simple, transparent pricing for Circle of Peers membership."
    
    render 'landing/pricing'
  end
  
  def contact
    @page_title = "Contact - Circle of Peers"
    @meta_description = "Get in touch with the Circle of Peers team."
    
    render 'landing/contact'
  end
  
  # API endpoint for refreshing statistics (admin only)
  def refresh_statistics
    if current_user&.admin?
      CommunityStatistics.refresh_statistics
      render json: { success: true, message: 'Statistics refreshed successfully' }
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
  
  private
  
  def set_meta_tags
    @meta_tags = {
      'og:title' => @page_title,
      'og:description' => @meta_description,
      'og:type' => 'website',
      'og:url' => request.original_url,
      'twitter:card' => 'summary_large_image',
      'twitter:title' => @page_title,
      'twitter:description' => @meta_description
    }
  end
end 