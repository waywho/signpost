class CodebaseAnalysis < ApplicationRecord
  belongs_to :slack_thread
  belongs_to :delegation, optional: true

  enum :status, { pending: 0, running: 1, completed: 2, failed: 3 }, default: :pending

  validates :repo_name, presence: true
  validates :repo_path, presence: true
end
