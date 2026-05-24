class SlackTopicMessage < ApplicationRecord
  belongs_to :slack_topic
  belongs_to :slack_message
end
