class PrReview < ApplicationRecord
  belongs_to :developer, optional: true

  enum :recommendation, { approve: 0, request_changes: 1, needs_discussion: 2 }
  enum :risk_level, { low: 0, medium: 1, high: 2, critical: 3 }

  validates :pr_number, presence: true
  validates :repo, presence: true

  scope :recent, -> { order(reviewed_at: :desc) }
  scope :for_developer, ->(dev) { where(developer: dev) }
end
