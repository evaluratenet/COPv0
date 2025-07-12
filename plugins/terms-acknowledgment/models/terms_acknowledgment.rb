class TermsAcknowledgment < ActiveRecord::Base
  belongs_to :user
  
  validates :user_id, presence: true, uniqueness: true
  validates :terms_version, presence: true
  validates :status, inclusion: { in: %w[pending acknowledged declined] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :acknowledged, -> { where(status: 'acknowledged') }
  scope :declined, -> { where(status: 'declined') }
  scope :by_version, ->(version) { where(terms_version: version) }
  
  before_create :set_defaults
  after_update :update_user_fields, if: :saved_change_to_status?
  
  def self.acknowledge_for_user(user, ip_address = nil, user_agent = nil)
    acknowledgment = find_or_create_by(user_id: user.id)
    
    acknowledgment.update!(
      status: 'acknowledged',
      acknowledged_at: Time.current,
      ip_address: ip_address,
      user_agent: user_agent,
      terms_version: current_terms_version
    )
    
    acknowledgment
  end
  
  def self.decline_for_user(user, ip_address = nil, user_agent = nil)
    acknowledgment = find_or_create_by(user_id: user.id)
    
    acknowledgment.update!(
      status: 'declined',
      acknowledged_at: Time.current,
      ip_address: ip_address,
      user_agent: user_agent,
      terms_version: current_terms_version
    )
    
    acknowledgment
  end
  
  def self.current_terms_version
    '1.0.0'  # Update this when terms change
  end
  
  def self.terms_updated?
    # Check if current terms version is different from user's acknowledged version
    # This would be used to require re-acknowledgment when terms change
    false  # Implement logic based on your needs
  end
  
  def acknowledged?
    status == 'acknowledged'
  end
  
  def pending?
    status == 'pending'
  end
  
  def declined?
    status == 'declined'
  end
  
  def requires_acknowledgment?
    pending? || terms_version != self.class.current_terms_version
  end
  
  def acknowledgment_age
    return nil unless acknowledged_at
    ((Time.current - acknowledged_at) / 1.day).round
  end
  
  def to_json(options = {})
    {
      id: id,
      user_id: user_id,
      status: status,
      terms_version: terms_version,
      acknowledged_at: acknowledged_at&.iso8601,
      ip_address: ip_address,
      user_agent: user_agent,
      requires_acknowledgment: requires_acknowledgment?,
      acknowledgment_age: acknowledgment_age
    }.to_json
  end
  
  private
  
  def set_defaults
    self.terms_version ||= self.class.current_terms_version
    self.status ||= 'pending'
  end
  
  def update_user_fields
    if acknowledged?
      user.update!(
        terms_acknowledged: true,
        terms_acknowledged_at: acknowledged_at
      )
    elsif declined?
      user.update!(
        terms_acknowledged: false,
        terms_acknowledged_at: nil
      )
    end
  end
end 