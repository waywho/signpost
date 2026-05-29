class DeveloperNote < ApplicationRecord
  belongs_to :developer

  enum :note_type, { good: 0, growth: 1, concern: 2, context: 3 }

  validates :content, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
