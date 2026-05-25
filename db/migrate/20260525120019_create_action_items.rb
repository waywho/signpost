class CreateActionItems < ActiveRecord::Migration[8.1]
  def change
    create_table :action_items, id: :uuid do |t|
      t.references :slack_topic, type: :uuid, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :slack_thread, type: :uuid, null: false, foreign_key: true
      t.integer :priority, null: false
      t.text :status, null: false, default: "pending"
      t.text :draft_title
      t.text :draft_body
      t.references :suggested_developer, type: :uuid, foreign_key: { to_table: :developers }
      t.text :suggestion_reason
      t.text :suggested_repo
      t.timestamptz :approved_at
      t.timestamptz :dismissed_at
      t.text :github_issue_url
      t.references :delegation, type: :uuid, foreign_key: true
      t.jsonb :related_items, default: []
      t.timestamps
    end

    add_index :action_items, :slack_topic_id, unique: true
    add_index :action_items, :status
    add_index :action_items, :priority
    add_check_constraint :action_items, "status IN ('pending', 'approved', 'dismissed')", name: "action_items_status_check"
  end
end
