class CreateSubscriptions < ActiveRecord::Migration[6.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stripe_subscription_id, null: false
      t.string :stripe_customer_id, null: false
      t.string :status, null: false, default: 'trialing'
      t.string :plan_type, null: false
      t.integer :amount, null: false
      t.string :currency, null: false, default: 'usd'
      t.datetime :current_period_start, null: false
      t.datetime :current_period_end, null: false
      t.datetime :trial_start
      t.datetime :trial_end
      t.datetime :canceled_at
      t.datetime :activated_at
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end
    
    add_index :subscriptions, :stripe_subscription_id, unique: true
    add_index :subscriptions, :stripe_customer_id
    add_index :subscriptions, :status
    add_index :subscriptions, :plan_type
    add_index :subscriptions, [:user_id, :status]
    add_index :subscriptions, :trial_end
  end
end 