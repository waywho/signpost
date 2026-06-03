class AddSlackTopicToDelegations < ActiveRecord::Migration[8.1]
  def change
    add_reference :delegations, :slack_topic, null: true, foreign_key: true, type: :uuid
  end
end
