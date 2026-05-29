class SlackThread < ApplicationRecord
  has_neighbors :embedding
  has_many :slack_messages, dependent: :destroy
  has_many :slack_topics, dependent: :destroy
  has_many :codebase_analyses, dependent: :destroy
  has_many :slack_topic_messages, through: :slack_topics

  enum :category, { architecture: 0, stakeholder: 1, team_decision: 2, incident: 3, other: 4 }
  enum :status, { new_thread: 0, triaged: 1, actioned: 2, archived: 3 }, default: :new_thread
  enum :capture_reason, { mention: 0, participation: 1, brain_emoji: 2, channel_stream: 3, manual: 4 }

  validates :slack_channel_id, presence: true
  validates :slack_thread_ts, presence: true, uniqueness: true

  scope :recent, -> { order(captured_at: :desc) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :pending_reanalysis, -> { where(pending_reanalysis: true) }
  scope :active, -> { where.not(status: :archived) }
  scope :uncompressed, -> { where(compressed: false) }
  scope :compressible, -> { uncompressed.where.not(id: SlackTopic.open.select(:slack_thread_id)) }
end
