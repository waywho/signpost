class AddDraftingToSlackTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :slack_topics, :drafting, :boolean, default: false, null: false
  end
end
