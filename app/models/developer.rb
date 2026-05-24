class Developer < ApplicationRecord
  has_many :oneone_sessions, dependent: :destroy
  has_many :developer_notes, dependent: :destroy
  has_many :delegations, dependent: :nullify

  validates :name, presence: true
  validates :level, inclusion: { in: %w[Junior Mid Senior Staff], allow_nil: true }

  scope :by_name, -> { order(:name) }
end
