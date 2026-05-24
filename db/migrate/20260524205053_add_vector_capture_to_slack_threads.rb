class AddVectorCaptureToSlackThreads < ActiveRecord::Migration[8.1]
  def change
    add_column :slack_threads, :embedding, :vector, limit: 1536
    add_column :slack_threads, :capture_reason, :text
    add_column :slack_threads, :status, :text, default: "new", null: false
    add_column :slack_threads, :pending_reanalysis, :boolean, default: false, null: false
    add_column :slack_threads, :last_analyzed_at, :timestamptz
    add_column :slack_threads, :compressed, :boolean, default: false, null: false

    add_check_constraint :slack_threads, "status IN ('new', 'triaged', 'actioned', 'archived')", name: "slack_threads_status_check"
    add_check_constraint :slack_threads, "capture_reason IN ('mention', 'participation', 'brain_emoji', 'channel_stream', 'manual') OR capture_reason IS NULL", name: "slack_threads_capture_reason_check"

    execute "CREATE INDEX index_slack_threads_on_embedding ON slack_threads USING hnsw (embedding vector_cosine_ops)"
  end
end
