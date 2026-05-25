class CreateOneoneSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :oneone_sessions, id: :uuid do |t|
      t.references :developer, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.date :session_date, null: false
      t.text :discussed
      t.text :wins
      t.text :challenges
      t.text :growth
      t.text :action_items
      t.text :private_notes
      t.text :summary
      t.timestamps
    end

    add_index :oneone_sessions, :session_date
  end
end
