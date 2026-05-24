class DailyLog < ApplicationRecord
  validates :log_date, presence: true, uniqueness: true

  scope :recent, -> { order(log_date: :desc) }

  def self.today
    find_or_initialize_by(log_date: Date.current)
  end
end
