class CreateSessionLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :session_logs do |t|
      t.references :user_session, null: false, foreign_key: true
      t.string :action, null: false
      t.string :ip_address, null: false
      t.text :user_agent, null: false
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end
    
    add_index :session_logs, :action
    add_index :session_logs, :created_at
    add_index :session_logs, [:user_session_id, :action]
  end
end 