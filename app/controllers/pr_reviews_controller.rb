class PrReviewsController < ApplicationController
  def index
    @pr_queue = begin
      service = GitHubService.new
      service.configured? ? service.pr_queue : nil
    rescue => e
      Rails.logger.error("PR queue fetch failed: #{e.message}")
      nil
    end

    @claude_configured = ClaudeService.new.configured?
    if @pr_queue&.any?
      pr_keys = @pr_queue.map { |pr| [pr[:repo], pr[:number]] }
      @analyzed_prs = PrReview.where(repo: pr_keys.map(&:first), pr_number: pr_keys.map(&:last))
                              .pluck(:repo, :pr_number).to_set
    else
      @analyzed_prs = Set.new
    end

    @pr_reviews = PrReview.recent
    @pr_reviews = @pr_reviews.where(repo: params[:repo]) if params[:repo].present?
    @pr_reviews = @pr_reviews.where(recommendation: params[:recommendation]) if params[:recommendation].present?
    @pr_reviews = @pr_reviews.where(risk_level: params[:risk_level]) if params[:risk_level].present?
  end

  def show
    @pr_review = PrReview.find(params[:id])
    @claude_configured = ClaudeService.new.configured?
    @github_configured = GitHubService.new.configured?
  end
end
