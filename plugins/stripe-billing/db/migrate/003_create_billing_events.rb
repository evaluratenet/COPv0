class CreateBillingEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :billing_events do |t|
      t.references :subscription, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :stripe_event_id, null: false
      t.boolean :success, default: true
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end
    
    add_index :billing_events, :event_type
    add_index :billing_events, :stripe_event_id, unique: true
    add_index :billing_events, :success
    add_index :billing_events, :created_at
    add_index :billing_events, [:subscription_id, :event_type]
  end
end 