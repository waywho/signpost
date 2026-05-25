class Developer < ApplicationRecord
  has_many :oneone_sessions, dependent: :destroy
  has_many :developer_notes, dependent: :destroy
  has_many :delegations, dependent: :nullify
  has_many :pr_reviews, dependent: :nullify

  validates :name, presence: true
  validates :level, inclusion: { in: %w[Junior Mid Senior Staff], allow_nil: true }

  scope :by_name, -> { order(:name) }

  before_validation :parse_skills_json

  private

  def parse_skills_json
    if skills.is_a?(String)
      self.skills = JSON.parse(skills)
    end
  rescue JSON::ParserError
    self.skills = []
  end
end
