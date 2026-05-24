class SlackTopic < ApplicationRecord
  belongs_to :slack_thread
  has_neighbors :embedding
  has_many :slack_topic_messages, dependent: :destroy
  has_many :slack_messages, through: :slack_topic_messages

  validates :title, :summary, presence: true
  validates :category, inclusion: { in: %w[bug feature question incident architecture process other], allow_nil: true }
  validates :urgency, inclusion: { in: %w[critical high medium low], allow_nil: true }
  validates :action_recommendation, inclusion: { in: %w[delegate create_ticket acknowledge discuss ignore], allow_nil: true }
  validates :status, inclusion: { in: %w[open actioned dismissed] }

  scope :open, -> { where(status: "open") }
  scope :by_urgency, -> { order(Arel.sql("CASE urgency WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 WHEN 'low' THEN 3 ELSE 4 END")) }
end
