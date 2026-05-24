class CreateSlackTopicMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :slack_topic_messages, id: :uuid do |t|
      t.references :slack_topic, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :slack_message, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
    end

    add_index :slack_topic_messages, [:slack_topic_id, :slack_message_id], unique: true, name: "idx_topic_messages_unique"
  end
end
