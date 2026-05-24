class Delegation < ApplicationRecord
  belongs_to :developer, optional: true

  validates :summary, presence: true
  validates :urgency, inclusion: { in: %w[Critical High Medium Low], allow_nil: true }
  validates :status, inclusion: { in: %w[delegated in_progress done blocked] }

  scope :active, -> { where.not(status: "done") }
  scope :by_urgency, -> { order(Arel.sql("CASE urgency WHEN 'Critical' THEN 0 WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 WHEN 'Low' THEN 3 END")) }
end
