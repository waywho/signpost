class PrReview < ApplicationRecord
  validates :pr_number, presence: true
  validates :repo, presence: true
  validates :recommendation, inclusion: { in: %w[APPROVE REQUEST_CHANGES NEEDS_DISCUSSION], allow_nil: true }
  validates :risk_level, inclusion: { in: %w[LOW MEDIUM HIGH CRITICAL], allow_nil: true }

  scope :recent, -> { order(reviewed_at: :desc) }
end
