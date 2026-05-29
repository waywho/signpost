class Commitment < ApplicationRecord
  enum :source, { manual: 0, slack: 1, meeting: 2 }

  validates :text, presence: true

  scope :pending, -> { where(done: false) }
  scope :due_soon, -> { pending.where("due_date <= ?", 3.days.from_now).order(:due_date) }
end
