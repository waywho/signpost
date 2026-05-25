class ActionItem < ApplicationRecord
  belongs_to :slack_topic
  belongs_to :slack_thread
  belongs_to :suggested_developer, class_name: "Developer", optional: true
  belongs_to :delegation, optional: true

  validates :priority, presence: true
  validates :status, inclusion: { in: %w[pending approved dismissed] }
  validates :slack_topic_id, uniqueness: true

  scope :pending, -> { where(status: "pending") }
  scope :by_priority, -> { order(:priority) }
end
