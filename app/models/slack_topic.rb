class SlackTopic < ApplicationRecord
  belongs_to :slack_thread
  has_neighbors :embedding
  has_many :slack_topic_messages, dependent: :destroy
  has_many :slack_messages, through: :slack_topic_messages
  has_many :action_items, dependent: :nullify
  has_one :delegation, dependent: :nullify

  enum :category, { bug: 0, feature: 1, question: 2, incident: 3, architecture: 4, process: 5, other: 6 }
  enum :urgency, { critical: 0, high: 1, medium: 2, low: 3 }
  enum :action_recommendation, { delegate: 0, create_ticket: 1, acknowledge: 2, discuss: 3, ignore: 4 }
  enum :status, { open: 0, actioned: 1, dismissed: 2 }

  validates :title, :summary, presence: true

  scope :by_urgency, -> { order(:urgency) }
end
