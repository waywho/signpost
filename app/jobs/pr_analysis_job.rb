class PrAnalysisJob < ApplicationJob
  queue_as :default

  def perform(repo:, pr_number:)
    PrAnalysisService.new.analyze(repo: repo, pr_number: pr_number)
  rescue => e
    Rails.logger.error("PrAnalysisJob failed for #{repo}##{pr_number}: #{e.message}")
  end
end
