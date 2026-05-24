class SlackMessage < ApplicationRecord
  belongs_to :slack_thread
  has_neighbors :embedding
  has_many :slack_topic_messages, dependent: :destroy
  has_many :slack_topics, through: :slack_topic_messages

  validates :message_ts, :content, presence: true
  validates :message_ts, uniqueness: { scope: :slack_thread_id }

  scope :chronological, -> { order(:message_ts_at) }
end
