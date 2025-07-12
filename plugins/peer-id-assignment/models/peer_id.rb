class PeerId < ActiveRecord::Base
  belongs_to :user
  
  validates :user_id, presence: true, uniqueness: true
  validates :peer_number, presence: true, uniqueness: true
  validates :display_name, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[active suspended inactive] }
  
  before_validation :generate_peer_number, on: :create
  before_validation :generate_display_name, on: :create
  
  scope :active, -> { where(status: 'active') }
  scope :suspended, -> { where(status: 'suspended') }
  scope :inactive, -> { where(status: 'inactive') }
  
  def self.assign_to_user(user)
    # Check if user already has a peer ID
    existing = find_by(user_id: user.id)
    return existing if existing
    
    # Create new peer ID
    peer_id = create!(
      user_id: user.id,
      assigned_at: Time.current
    )
    
    # Update user's custom field
    user.custom_fields['peer_id'] = peer_id.display_name
    user.save!
    
    # Log the assignment
    PeerIdAssignment.create!(
      user_id: user.id,
      peer_number: peer_id.peer_number,
      assigned_by: 'system',
      notes: 'Auto-assigned on user approval'
    )
    
    peer_id
  end
  
  def self.next_peer_number
    # Get the highest peer number and increment
    max_number = maximum(:peer_number) || 0
    (max_number.to_i + 1).to_s.rjust(4, '0')
  end
  
  def self.generate_display_name(peer_number)
    "Peer ##{peer_number}"
  end
  
  def suspend!
    update!(status: 'suspended')
    user.update!(custom_fields: user.custom_fields.merge('peer_id' => nil))
  end
  
  def activate!
    update!(status: 'active')
    user.update!(custom_fields: user.custom_fields.merge('peer_id' => display_name))
  end
  
  def deactivate!
    update!(status: 'inactive')
    user.update!(custom_fields: user.custom_fields.merge('peer_id' => nil))
  end
  
  private
  
  def generate_peer_number
    return if peer_number.present?
    self.peer_number = self.class.next_peer_number
  end
  
  def generate_display_name
    return if display_name.present?
    self.display_name = self.class.generate_display_name(peer_number)
  end
end

class PeerIdAssignment < ActiveRecord::Base
  belongs_to :user
  
  validates :user_id, presence: true
  validates :peer_number, presence: true
  validates :assigned_by, presence: true
end 