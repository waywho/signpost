class ActionItem < ApplicationRecord
  belongs_to :slack_topic
  belongs_to :slack_thread
  belongs_to :suggested_developer, class_name: "Developer", optional: true
  belongs_to :delegation, optional: true

  ACTION_TYPES = %w[create_ticket delegate acknowledge discuss ignore].freeze

  validates :priority, presence: true
  validates :status, inclusion: { in: %w[pending approved dismissed ignored] }
  validates :action_type, inclusion: { in: ACTION_TYPES }
  validates :slack_topic_id, uniqueness: true

  scope :pending, -> { where(status: "pending") }
  scope :ignored, -> { where(status: "ignored") }
  scope :actionable, -> { pending.where(action_type: %w[create_ticket delegate]) }
  scope :discussions, -> { pending.where(action_type: "discuss") }
  scope :acknowledgements, -> { pending.where(action_type: "acknowledge") }
  scope :by_priority, -> { order(:priority) }
end
