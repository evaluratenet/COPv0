class TermsController < ApplicationController
  before_action :ensure_logged_in, except: [:show]
  before_action :set_acknowledgment, only: [:acknowledge, :status]
  
  def show
    # Display terms and conditions page
    @terms_content = load_terms_content
    @key_highlights = load_key_highlights
    
    if current_user
      @acknowledgment = TermsAcknowledgment.find_by(user_id: current_user.id)
    end
    
    render layout: 'application'
  end
  
  def acknowledge
    if params[:action_type] == 'acknowledge'
      # User acknowledges terms
      @acknowledgment = TermsAcknowledgment.acknowledge_for_user(
        current_user,
        request.remote_ip,
        request.user_agent
      )
      
      # Send confirmation email
      Jobs.enqueue(:terms_acknowledgment_email, user_id: current_user.id)
      
      render json: { 
        success: true, 
        message: 'Terms and Conditions acknowledged successfully.',
        redirect_url: '/dashboard'
      }
    elsif params[:action_type] == 'decline'
      # User declines terms
      @acknowledgment = TermsAcknowledgment.decline_for_user(
        current_user,
        request.remote_ip,
        request.user_agent
      )
      
      # Log out user and redirect to signup
      logout
      
      render json: { 
        success: true, 
        message: 'Terms and Conditions declined. You must accept the terms to use the platform.',
        redirect_url: '/signup'
      }
    else
      render json: { error: 'Invalid action type' }, status: :bad_request
    end
  end
  
  def status
    if @acknowledgment
      render json: {
        acknowledged: @acknowledgment.acknowledged?,
        pending: @acknowledgment.pending?,
        declined: @acknowledgment.declined?,
        requires_acknowledgment: @acknowledgment.requires_acknowledgment?,
        terms_version: @acknowledgment.terms_version,
        acknowledged_at: @acknowledgment.acknowledged_at&.iso8601
      }
    else
      render json: { error: 'No acknowledgment record found' }, status: :not_found
    end
  end
  
  private
  
  def set_acknowledgment
    @acknowledgment = TermsAcknowledgment.find_by(user_id: current_user.id)
  end
  
  def load_terms_content
    # Load terms content from file or database
    # For now, return the terms content
    <<~TERMS
      # Circle of Peers - Terms and Conditions
      
      **Effective Date:** #{Date.current}
      **Last Updated:** #{Date.current}
      
      ## 1. ACCEPTANCE OF TERMS
      
      By accessing or using the Circle of Peers platform ("Service"), you agree to be bound by these Terms and Conditions ("Terms"). If you do not agree to these Terms, you must not use the Service.
      
      ## 2. SERVICE DESCRIPTION
      
      Circle of Peers is a private, invitation-based digital forum designed exclusively for verified C-level executives. The Service provides anonymous discussion environments for leadership, strategy, growth, HR, M&A, and other executive themes.
      
      ## 3. ELIGIBILITY AND VERIFICATION
      
      ### 3.1 Eligibility Requirements
      - You must be a current or former C-level executive (CEO, CFO, CTO, COO, etc.) or equivalent senior leadership position
      - You must provide verifiable professional credentials
      - You must complete the verification process including reference checks
      - You must be at least 18 years old
      
      ## 4. USER ACCOUNTS AND SECURITY
      
      ### 4.1 Account Creation
      - One account per person
      - Sharing of login credentials is strictly prohibited
      - Accounts are non-transferable
      - You are responsible for maintaining account security
      
      ### 4.2 Two-Factor Authentication
      - 2FA is mandatory for all accounts
      - Email-based verification required for each login
      - Failure to complete 2FA may result in account suspension
      
      ## 5. PRIVACY AND ANONYMITY
      
      ### 5.1 Anonymous Participation
      - All users are assigned fixed anonymous Peer IDs
      - Real identities are not disclosed in discussions
      - Peer IDs remain consistent across sessions
      - Identity revelation is only permitted through mutual consent
      
      ### 5.2 Data Protection
      - Personal information is collected for verification only
      - Discussion content is encrypted in transit and at rest
      - No user tracking, profiling, or third-party data sharing
      - Data is never sold or shared with advertisers
      
      ## 6. ACCEPTABLE USE POLICY
      
      ### 6.1 Prohibited Activities
      **VIOLATION OF THESE TERMS WILL RESULT IN IMMEDIATE ACCOUNT SUSPENSION:**
      
      - **No Solicitation**: Promoting products, services, or business opportunities
      - **No Personal Data Sharing**: Revealing personal contact information, addresses, or private details
      - **No Harassment**: Hostile, threatening, or inappropriate behavior
      - **No Confidential Information**: Sharing company secrets or proprietary information
      - **No Identity Disclosure**: Revealing your real identity without mutual consent
      - **No Spam**: Automated or repetitive content
      - **No Off-Topic Content**: Content unrelated to executive leadership discussions
      
      ### 6.2 Content Standards
      - Maintain professional and respectful tone
      - Contribute valuable insights and experiences
      - Respect the anonymity of other members
      - Follow community guidelines and room-specific rules
      
      ## 7. CONTENT MODERATION
      
      ### 7.1 Moderation System
      - AI-powered content scanning for violations
      - User flagging system for community reporting
      - Admin review of all flagged content
      - Severity-based actions including post removal and account suspension
      
      ### 7.2 Violation Consequences
      - **Critical Violations**: Immediate account suspension and post deletion
      - **High Severity**: Post hiding and warning emails
      - **Medium Severity**: Post hiding
      - **Minor Violations**: Flagging for review
      
      ## 8. SUBSCRIPTION AND PAYMENT
      
      ### 8.1 Trial Period
      - 30-day free trial for new users
      - Full access to all platform features during trial
      - No credit card required for trial period
      
      ### 8.2 Subscription Terms
      - $50 USD per month after trial period
      - Automatic billing on monthly anniversary
      - Cancellation available at any time
      - No refunds for partial months
      
      ## 9. TERMINATION
      
      ### 9.1 Account Termination
      - Users may cancel subscription at any time
      - Circle of Peers may terminate accounts for violations
      - Data deletion upon termination request
      - No refunds for violations resulting in termination
      
      ## 10. LIMITATION OF LIABILITY
      
      - Maximum liability limited to subscription fees paid
      - No liability for indirect or consequential damages
      - Users assume responsibility for their actions
      
      ## 11. CONTACT INFORMATION
      
      - Email: admin@circleofpeers.net
      - Support hours: Monday-Friday, 9 AM - 5 PM EST
      
      ---
      
      **By using the Circle of Peers platform, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.**
    TERMS
  end
  
  def load_key_highlights
    [
      {
        title: "No Solicitation",
        description: "Promoting products, services, or business opportunities is strictly prohibited and will result in immediate account suspension",
        icon: "🚫"
      },
      {
        title: "No Personal Data Sharing",
        description: "Revealing personal contact information, addresses, or private details is not allowed",
        icon: "🔒"
      },
      {
        title: "No Harassment",
        description: "Hostile, threatening, or inappropriate behavior will result in immediate suspension",
        icon: "⚠️"
      },
      {
        title: "No Confidential Information",
        description: "Sharing company secrets or proprietary information is prohibited",
        icon: "🤐"
      },
      {
        title: "Immediate Suspension",
        description: "Violation of these terms will result in immediate account suspension without refund",
        icon: "⚡"
      },
      {
        title: "Anonymous Participation",
        description: "Your real identity will remain confidential; you will be assigned an anonymous Peer ID",
        icon: "🕵️"
      },
      {
        title: "Subscription Terms",
        description: "30-day free trial, then $50/month. Cancel anytime.",
        icon: "💳"
      }
    ]
  end
end 