class CreateUserSessions < ActiveRecord::Migration[6.1]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :session_id, null: false
      t.string :ip_address, null: false
      t.text :user_agent, null: false
      t.boolean :active, default: true, null: false
      t.datetime :last_activity, null: false
      t.datetime :ended_at
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end
    
    add_index :user_sessions, :session_id, unique: true
    add_index :user_sessions, :active
    add_index :user_sessions, :last_activity
    add_index :user_sessions, [:user_id, :active]
  end
end 