class NoiseFilter < ApplicationRecord
  validates :category, :description, presence: true
  scope :enabled, -> { where(enabled: true) }
end
