class OneoneSession < ApplicationRecord
  belongs_to :developer

  validates :session_date, presence: true

  scope :recent, -> { order(session_date: :desc) }
end
