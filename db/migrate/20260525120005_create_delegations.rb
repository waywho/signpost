class CreateDelegations < ActiveRecord::Migration[8.1]
  def change
    create_table :delegations, id: :uuid do |t|
      t.references :developer, type: :uuid, foreign_key: { on_delete: :nullify }
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
      t.text :status, null: false, default: "delegated"
      t.timestamptz :delegated_at, default: -> { "NOW()" }
      t.timestamptz :resolved_at
      t.timestamps
    end

    add_index :delegations, :status
    add_check_constraint :delegations, "urgency IN ('Critical', 'High', 'Medium', 'Low') OR urgency IS NULL", name: "delegations_urgency_check"
    add_check_constraint :delegations, "status IN ('delegated', 'in_progress', 'done', 'blocked')", name: "delegations_status_check"
  end
end
