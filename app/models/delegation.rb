class Delegation < ApplicationRecord
  belongs_to :developer, optional: true

  enum :urgency, { critical: 0, high: 1, medium: 2, low: 3 }
  enum :status, { delegated: 0, in_progress: 1, done: 2, blocked: 3 }, default: :delegated

  validates :summary, presence: true

  scope :active, -> { where.not(status: :done) }
  scope :by_urgency, -> { order(:urgency) }

  before_save :set_resolved_at

  private

  def set_resolved_at
    if status_changed? && done?
      self.resolved_at = Time.current
    elsif status_changed? && status_previously_was == "done"
      self.resolved_at = nil
    end
  end
end
