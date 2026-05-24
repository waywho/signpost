class SlackThread < ApplicationRecord
  validates :slack_channel_id, presence: true
  validates :slack_thread_ts, presence: true, uniqueness: true
  validates :category, inclusion: { in: %w[architecture stakeholder team-decision incident other], allow_nil: true }

  scope :recent, -> { order(captured_at: :desc) }
  scope :by_category, ->(cat) { where(category: cat) }
end
