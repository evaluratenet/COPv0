class PaymentMethod < ActiveRecord::Base
  belongs_to :subscription
  
  validates :stripe_payment_method_id, presence: true, uniqueness: true
  validates :subscription_id, presence: true
  validates :type, presence: true, inclusion: { in: %w[card bank_account] }
  validates :brand, presence: true, if: -> { type == 'card' }
  validates :last4, presence: true, length: { is: 4 }
  validates :exp_month, presence: true, numericality: { greater_than: 0, less_than: 13 }, if: -> { type == 'card' }
  validates :exp_year, presence: true, numericality: { greater_than: Time.current.year - 1 }, if: -> { type == 'card' }
  
  scope :cards, -> { where(type: 'card') }
  scope :bank_accounts, -> { where(type: 'bank_account') }
  scope :default, -> { where(is_default: true) }
  
  before_save :ensure_single_default
  
  def self.create_from_stripe(stripe_payment_method, subscription)
    # Set all other payment methods for this subscription as non-default
    subscription.payment_methods.update_all(is_default: false)
    
    create!(
      subscription_id: subscription.id,
      stripe_payment_method_id: stripe_payment_method.id,
      type: stripe_payment_method.type,
      brand: stripe_payment_method.card&.brand,
      last4: stripe_payment_method.card&.last4 || stripe_payment_method.bank_account&.last4,
      exp_month: stripe_payment_method.card&.exp_month,
      exp_year: stripe_payment_method.card&.exp_year,
      is_default: true,
      metadata: {
        fingerprint: stripe_payment_method.card&.fingerprint,
        country: stripe_payment_method.card&.country,
        funding: stripe_payment_method.card&.funding
      }
    )
  end
  
  def self.update_from_stripe(stripe_payment_method)
    payment_method = find_by(stripe_payment_method_id: stripe_payment_method.id)
    return unless payment_method
    
    payment_method.update!(
      brand: stripe_payment_method.card&.brand,
      last4: stripe_payment_method.card&.last4 || stripe_payment_method.bank_account&.last4,
      exp_month: stripe_payment_method.card&.exp_month,
      exp_year: stripe_payment_method.card&.exp_year,
      metadata: {
        fingerprint: stripe_payment_method.card&.fingerprint,
        country: stripe_payment_method.card&.country,
        funding: stripe_payment_method.card&.funding
      }
    )
  end
  
  def is_expired?
    return false unless exp_month && exp_year
    
    current_date = Time.current
    exp_year < current_date.year || (exp_year == current_date.year && exp_month < current_date.month)
  end
  
  def expires_soon?
    return false unless exp_month && exp_year
    
    current_date = Time.current
    months_until_expiry = (exp_year - current_date.year) * 12 + (exp_month - current_date.month)
    months_until_expiry <= 3
  end
  
  def display_name
    if type == 'card'
      "#{brand&.titleize} ending in #{last4}"
    else
      "Bank account ending in #{last4}"
    end
  end
  
  def masked_number
    if type == 'card'
      "**** **** **** #{last4}"
    else
      "**** #{last4}"
    end
  end
  
  def expiry_display
    return nil unless exp_month && exp_year
    "#{exp_month.to_s.rjust(2, '0')}/#{exp_year}"
  end
  
  def set_as_default
    # Remove default from other payment methods
    subscription.payment_methods.where.not(id: id).update_all(is_default: false)
    
    # Set this as default
    update!(is_default: true)
    
    # Update in Stripe
    Stripe.api_key = SiteSetting.stripe_secret_key
    customer = Stripe::Customer.retrieve(subscription.stripe_customer_id)
    customer.invoice_settings.default_payment_method = stripe_payment_method_id
    customer.save
  end
  
  def delete_from_stripe
    Stripe.api_key = SiteSetting.stripe_secret_key
    
    begin
      Stripe::PaymentMethod.detach(stripe_payment_method_id)
    rescue Stripe::InvalidRequestError => e
      Rails.logger.error "Failed to delete payment method #{stripe_payment_method_id}: #{e.message}"
    end
    
    destroy
  end
  
  private
  
  def ensure_single_default
    if is_default?
      subscription.payment_methods.where.not(id: id).update_all(is_default: false)
    end
  end
end 