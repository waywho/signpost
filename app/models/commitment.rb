class Commitment < ApplicationRecord
  validates :text, presence: true
  validates :source, inclusion: { in: %w[manual slack meeting], allow_nil: true }

  scope :pending, -> { where(done: false) }
  scope :due_soon, -> { pending.where("due_date <= ?", 3.days.from_now).order(:due_date) }
end
