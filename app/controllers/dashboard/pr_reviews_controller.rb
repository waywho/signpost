class Dashboard::PrReviewsController < ApplicationController
  def show
    @recent_pr_reviews = PrReview.recent.limit(5)
    @pr_queue = begin
      service = GitHubService.new
      service.configured? ? service.pr_queue : nil
    rescue => e
      Rails.logger.error("Dashboard PR queue failed: #{e.message}")
      nil
    end
  end
end
