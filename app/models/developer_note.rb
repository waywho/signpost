class DeveloperNote < ApplicationRecord
  belongs_to :developer

  validates :content, presence: true
  validates :note_type, inclusion: { in: %w[good growth concern context], allow_nil: true }

  scope :recent, -> { order(created_at: :desc) }
end
