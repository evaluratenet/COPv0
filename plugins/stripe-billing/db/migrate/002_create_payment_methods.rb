class CreatePaymentMethods < ActiveRecord::Migration[6.1]
  def change
    create_table :payment_methods do |t|
      t.references :subscription, null: false, foreign_key: true
      t.string :stripe_payment_method_id, null: false
      t.string :type, null: false
      t.string :brand
      t.string :last4, null: false
      t.integer :exp_month
      t.integer :exp_year
      t.boolean :is_default, default: false
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end
    
    add_index :payment_methods, :stripe_payment_method_id, unique: true
    add_index :payment_methods, :type
    add_index :payment_methods, :is_default
    add_index :payment_methods, [:subscription_id, :is_default]
  end
end 