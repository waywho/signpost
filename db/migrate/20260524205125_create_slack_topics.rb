class CreateSlackTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :slack_topics, id: :uuid do |t|
      t.references :slack_thread, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.text :title, null: false
      t.text :summary, null: false
      t.text :category
      t.text :urgency
      t.text :action_recommendation
      t.text :status, null: false, default: "open"
      t.timestamps
    end

    add_column :slack_topics, :embedding, :vector, limit: 1536
    add_check_constraint :slack_topics, "status IN ('open', 'actioned', 'dismissed')", name: "slack_topics_status_check"
    execute "CREATE INDEX index_slack_topics_on_embedding ON slack_topics USING hnsw (embedding vector_cosine_ops)"
  end
end
