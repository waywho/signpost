class CreateSlackMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :slack_messages, id: :uuid do |t|
      t.references :slack_thread, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.text :message_ts, null: false
      t.text :user_id
      t.text :user_name
      t.text :content, null: false
      t.text :mentioned_users, array: true
      t.timestamptz :message_ts_at
      t.timestamps
    end

    add_column :slack_messages, :embedding, :vector, limit: 1536

    add_index :slack_messages, [:slack_thread_id, :message_ts], unique: true
    add_index :slack_messages, :mentioned_users, using: :gin

    execute "CREATE INDEX index_slack_messages_on_embedding ON slack_messages USING hnsw (embedding vector_cosine_ops)"
  end
end
