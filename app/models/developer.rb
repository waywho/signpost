class Developer < ApplicationRecord
  has_many :oneone_sessions, dependent: :destroy
  has_many :developer_notes, dependent: :destroy
  has_many :delegations, dependent: :nullify
  has_many :pr_reviews, dependent: :nullify

  enum :level, { junior: 0, mid: 1, senior: 2, staff: 3 }

  validates :name, presence: true

  scope :by_name, -> { order(:name) }

  before_validation :parse_skills_json

  def slack_mention
    return nil if slack_handle.blank?

    handle = slack_handle.to_s.strip
    return nil if handle.blank?

    handle.include?("@") ? handle : "@#{handle}"
  end

  private

  def parse_skills_json
    if skills.is_a?(String)
      self.skills = JSON.parse(skills)
    end
  rescue JSON::ParserError
    self.skills = []
  end
end
