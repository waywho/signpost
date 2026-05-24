class CreateDelegations < ActiveRecord::Migration[8.1]
  def change
    create_table :delegations, id: :uuid do |t|
      t.references :developer, foreign_key: { on_delete: :nullify }, type: :uuid
      t.text :developer_name
      t.text :summary, null: false
      t.text :urgency
      t.text :issue_type
      t.text :source_channel
      t.text :source_user
      t.text :slack_channel_id
      t.text :slack_thread_ts
      t.text :github_issue_url
      t.text :handoff_message
      t.text :codebase_context
      t.text :status, default: "delegated"
      t.timestamptz :delegated_at, default: -> { "NOW()" }
      t.timestamptz :resolved_at

      t.timestamps
    end

    add_check_constraint :delegations, "urgency IN ('Critical', 'High', 'Medium', 'Low')", name: "delegations_urgency_check"
    add_check_constraint :delegations, "status IN ('delegated', 'in_progress', 'done', 'blocked')", name: "delegations_status_check"
    add_index :delegations, :status
  end
end
