class VerificationCriteria < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :weight, numericality: { greater_than: 0 }
  
  scope :required, -> { where(required: true) }
  scope :optional, -> { where(required: false) }
  scope :by_weight, -> { order(weight: :desc) }
  
  def self.default_criteria
    [
      {
        name: 'executive_role',
        description: 'Verifies the user holds a C-level or equivalent executive position',
        weight: 5,
        required: true,
        ai_prompts: [
          'Analyze the job title and company information to determine if this person holds a C-level or equivalent executive position.',
          'Look for titles like CEO, CFO, CTO, COO, President, VP, Director, or equivalent senior leadership roles.',
          'Consider company size and industry when evaluating seniority level.'
        ]
      },
      {
        name: 'professional_credibility',
        description: 'Assesses the professional credibility and background',
        weight: 4,
        required: true,
        ai_prompts: [
          'Evaluate the LinkedIn profile and professional background for credibility.',
          'Check for consistent professional history and appropriate career progression.',
          'Look for red flags like inconsistent employment history or suspicious patterns.'
        ]
      },
      {
        name: 'email_domain',
        description: 'Evaluates the email domain for corporate vs personal use',
        weight: 3,
        required: false,
        ai_prompts: [
          'Assess whether the email domain is corporate or personal.',
          'Corporate domains generally indicate higher credibility.',
          'Personal domains (Gmail, Yahoo, etc.) require additional verification.'
        ]
      },
      {
        name: 'company_verification',
        description: 'Verifies the company information and legitimacy',
        weight: 4,
        required: true,
        ai_prompts: [
          'Verify that the company exists and is legitimate.',
          'Check if the company size and industry align with executive roles.',
          'Look for any suspicious or non-existent company information.'
        ]
      },
      {
        name: 'linkedin_quality',
        description: 'Assesses the quality and completeness of LinkedIn profile',
        weight: 3,
        required: true,
        ai_prompts: [
          'Evaluate the LinkedIn profile for completeness and professionalism.',
          'Check for appropriate connections, endorsements, and activity.',
          'Look for signs of a genuine professional network.'
        ]
      },
      {
        name: 'communication_quality',
        description: 'Evaluates the quality of communication in the application',
        weight: 2,
        required: false,
        ai_prompts: [
          'Assess the quality and professionalism of written communication.',
          'Look for appropriate language and professional tone.',
          'Check for signs of automated or suspicious communication patterns.'
        ]
      },
      {
        name: 'reference_quality',
        description: 'Evaluates the quality of provided references',
        weight: 4,
        required: true,
        ai_prompts: [
          'Analyze the reference responses for authenticity and credibility.',
          'Check if references confirm the executive role and professional standing.',
          'Look for consistent and credible reference feedback.'
        ]
      },
      {
        name: 'risk_assessment',
        description: 'Identifies potential risk factors and red flags',
        weight: 5,
        required: true,
        ai_prompts: [
          'Identify any potential risk factors or red flags in the application.',
          'Look for signs of fraud, misrepresentation, or suspicious behavior.',
          'Assess overall risk level based on all available information.'
        ]
      }
    ]
  end
  
  def self.initialize_defaults
    default_criteria.each do |criteria_data|
      find_or_create_by(name: criteria_data[:name]) do |criteria|
        criteria.description = criteria_data[:description]
        criteria.weight = criteria_data[:weight]
        criteria.required = criteria_data[:required]
        criteria.ai_prompts = criteria_data[:ai_prompts]
      end
    end
  end
  
  def ai_prompt_for_analysis
    prompts = ai_prompts || []
    prompts.join("\n\n")
  end
  
  def required?
    required
  end
  
  def optional?
    !required
  end
  
  def high_weight?
    weight >= 4
  end
  
  def medium_weight?
    weight >= 2 && weight < 4
  end
  
  def low_weight?
    weight < 2
  end
end 