class SlackThread < ApplicationRecord
  has_neighbors :embedding
  has_many :slack_messages, dependent: :destroy
  has_many :slack_topics, dependent: :destroy
  has_many :slack_topic_messages, through: :slack_topics

  validates :slack_channel_id, presence: true
  validates :slack_thread_ts, presence: true, uniqueness: true
  validates :category, inclusion: { in: %w[architecture stakeholder team-decision incident other], allow_nil: true }
  validates :status, inclusion: { in: %w[new triaged actioned archived] }
  validates :capture_reason, inclusion: { in: %w[mention participation brain_emoji channel_stream manual], allow_nil: true }

  scope :recent, -> { order(captured_at: :desc) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :pending_reanalysis, -> { where(pending_reanalysis: true) }
  scope :active, -> { where.not(status: "archived") }
  scope :uncompressed, -> { where(compressed: false) }
  scope :compressible, -> { uncompressed.where.not(id: SlackTopic.open.select(:slack_thread_id)) }
end
