class UserPrivacySetting < ActiveRecord::Base
  belongs_to :user
  
  validates :user_id, presence: true, uniqueness: true
  validates :profile_visible, inclusion: { in: [true, false] }
  validates :contactable, inclusion: { in: [true, false] }
  validates :show_name, inclusion: { in: [true, false] }
  validates :show_company, inclusion: { in: [true, false] }
  validates :show_title, inclusion: { in: [true, false] }
  validates :show_email, inclusion: { in: [true, false] }
  
  scope :profile_visible, -> { where(profile_visible: true) }
  scope :contactable, -> { where(contactable: true) }
  
  before_create :set_defaults
  
  def self.create_for_user(user)
    # Check if settings already exist
    existing = find_by(user_id: user.id)
    return existing if existing
    
    # Create default settings (all off by default)
    create!(
      user_id: user.id,
      profile_visible: false,
      contactable: false,
      show_name: false,
      show_company: false,
      show_title: false,
      show_email: false
    )
  end
  
  def update_settings(params)
    update!(
      profile_visible: params[:profile_visible] == '1',
      contactable: params[:contactable] == '1',
      show_name: params[:show_name] == '1',
      show_company: params[:show_company] == '1',
      show_title: params[:show_title] == '1',
      show_email: params[:show_email] == '1'
    )
  end
  
  def privacy_summary
    if profile_visible
      visible_fields = []
      visible_fields << 'Name' if show_name
      visible_fields << 'Company' if show_company
      visible_fields << 'Title' if show_title
      visible_fields << 'Email' if show_email
      
      if visible_fields.any?
        "Profile visible with: #{visible_fields.join(', ')}"
      else
        "Profile visible (no details shown)"
      end
    else
      "Profile hidden"
    end
  end
  
  def contact_status
    if contactable
      "Open to contact requests"
    else
      "Not accepting contact requests"
    end
  end
  
  def visible_fields_count
    [show_name, show_company, show_title, show_email].count(true)
  end
  
  def has_any_visible_fields?
    show_name || show_company || show_title || show_email
  end
  
  def privacy_level
    if !profile_visible
      'hidden'
    elsif !has_any_visible_fields?
      'minimal'
    elsif visible_fields_count <= 2
      'limited'
    else
      'open'
    end
  end
  
  def privacy_level_description
    case privacy_level
    when 'hidden'
      'Profile completely hidden from other users'
    when 'minimal'
      'Profile visible but no personal details shown'
    when 'limited'
      'Some profile details visible to other users'
    when 'open'
      'Most profile details visible to other users'
    end
  end
  
  def can_be_contacted?
    contactable
  end
  
  def profile_accessible?
    profile_visible
  end
  
  private
  
  def set_defaults
    self.profile_visible ||= false
    self.contactable ||= false
    self.show_name ||= false
    self.show_company ||= false
    self.show_title ||= false
    self.show_email ||= false
  end
end 