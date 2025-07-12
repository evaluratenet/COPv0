class ViolationType < ActiveRecord::Base
  has_many :post_flags
  
  validates :name, presence: true, uniqueness: true
  validates :severity, inclusion: { in: 1..5 }
  validates :ai_detectable, inclusion: { in: [true, false] }
  validates :user_reportable, inclusion: { in: [true, false] }
  
  scope :ai_detectable, -> { where(ai_detectable: true) }
  scope :user_reportable, -> { where(user_reportable: true) }
  scope :by_severity, ->(severity) { where(severity: severity) }
  scope :high_severity, -> { where('severity >= ?', 4) }
  scope :critical, -> { where(severity: 5) }
  
  def self.find_by_name(name)
    find_by(name: name.to_s.downcase)
  end
  
  def self.solicitation
    find_by_name('solicitation')
  end
  
  def self.pii
    find_by_name('pii')
  end
  
  def self.harassment
    find_by_name('harassment')
  end
  
  def self.confidential
    find_by_name('confidential')
  end
  
  def self.off_topic
    find_by_name('off_topic')
  end
  
  def self.spam
    find_by_name('spam')
  end
  
  def self.identity_leak
    find_by_name('identity_leak')
  end
  
  def self.inappropriate
    find_by_name('inappropriate')
  end
  
  def severity_label
    case severity
    when 1 then 'Low'
    when 2 then 'Minor'
    when 3 then 'Medium'
    when 4 then 'High'
    when 5 then 'Critical'
    else 'Unknown'
    end
  end
  
  def severity_color
    case severity
    when 1 then 'green'
    when 2 then 'blue'
    when 3 then 'yellow'
    when 4 then 'orange'
    when 5 then 'red'
    else 'gray'
    end
  end
  
  def can_be_flagged_by_ai?
    ai_detectable
  end
  
  def can_be_flagged_by_user?
    user_reportable
  end
  
  def requires_immediate_action?
    severity >= 4
  end
  
  def auto_hide_post?
    severity >= 3
  end
  
  def auto_suspend_user?
    severity == 5
  end
  
  def to_json(options = {})
    {
      id: id,
      name: name,
      description: description,
      severity: severity,
      severity_label: severity_label,
      severity_color: severity_color,
      ai_detectable: ai_detectable,
      user_reportable: user_reportable,
      requires_immediate_action: requires_immediate_action?,
      auto_hide_post: auto_hide_post?,
      auto_suspend_user: auto_suspend_user?
    }.to_json
  end
end 