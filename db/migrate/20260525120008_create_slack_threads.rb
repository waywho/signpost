class CreateSlackThreads < ActiveRecord::Migration[8.1]
  def change
    create_table :slack_threads, id: :uuid do |t|
      t.text :slack_channel_id, null: false
      t.text :slack_channel_name
      t.text :slack_thread_ts, null: false
      t.text :slack_url
      t.text :title
      t.text :category
      t.text :summary
      t.text :participants, array: true
      t.text :keywords, array: true
      t.text :obsidian_path
      t.jsonb :raw_messages, default: []
      t.timestamptz :captured_at, default: -> { "NOW()" }
      # Vector capture fields
      t.text :capture_reason
      t.text :status, null: false, default: "new"
      t.boolean :pending_reanalysis, null: false, default: false
      t.timestamptz :last_analyzed_at
      t.boolean :compressed, null: false, default: false
      t.timestamps
    end

    add_column :slack_threads, :embedding, :vector, limit: 1536

    add_index :slack_threads, :slack_thread_ts, unique: true
    add_index :slack_threads, [ :slack_channel_id, :slack_thread_ts ], unique: true
    add_index :slack_threads, :category
    add_index :slack_threads, :keywords, using: :gin
    add_index :slack_threads, :status

    add_check_constraint :slack_threads, "category IN ('architecture', 'stakeholder', 'team-decision', 'incident', 'other') OR category IS NULL", name: "slack_threads_category_check"
    add_check_constraint :slack_threads, "status IN ('new', 'triaged', 'actioned', 'archived')", name: "slack_threads_status_check"
    add_check_constraint :slack_threads, "capture_reason IN ('mention', 'participation', 'brain_emoji', 'channel_stream', 'manual') OR capture_reason IS NULL", name: "slack_threads_capture_reason_check"

    execute "CREATE INDEX index_slack_threads_on_embedding ON slack_threads USING hnsw (embedding vector_cosine_ops)"
  end
end
