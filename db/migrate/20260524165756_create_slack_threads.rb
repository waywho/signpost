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
      t.text :obsidian_path
      t.jsonb :raw_messages, default: []
      t.timestamptz :captured_at, default: -> { "NOW()" }
      t.text :participants, array: true
      t.text :keywords, array: true

      t.timestamps
    end

    add_check_constraint :slack_threads, "category IN ('architecture', 'stakeholder', 'team-decision', 'incident', 'other')", name: "slack_threads_category_check"
    add_index :slack_threads, [:slack_channel_id, :slack_thread_ts], unique: true
    add_index :slack_threads, :slack_thread_ts, unique: true
    add_index :slack_threads, :category
    add_index :slack_threads, :keywords, using: :gin
  end
end
