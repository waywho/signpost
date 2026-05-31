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
                              .pluck(:repo, :pr_number, :id)
                              .to_h { |repo, pr_number, id| [[repo, pr_number], id] }
    else
      @analyzed_prs = {}
    end

    @pr_reviews = PrReview.recent
    @pr_reviews = @pr_reviews.where(repo: params[:repo]) if params[:repo].present?
    @pr_reviews = @pr_reviews.where(recommendation: params[:recommendation]) if params[:recommendation].present?
    @pr_reviews = @pr_reviews.where(risk_level: params[:risk_level]) if params[:risk_level].present?
  end

  def create
    @pr_review = PrReview.find_or_create_by!(repo: params[:repo], pr_number: params[:pr_number].to_i) do |pr|
      pr.pr_title = params[:pr_title]
      pr.pr_author = params[:pr_author]
    end
    redirect_to @pr_review
  end

  def show
    @pr_review = PrReview.find(params[:id])
    @claude_configured = ClaudeService.new.configured?
    @github_configured = GitHubService.new.configured?
    @stream_name = "pr_analysis:#{@pr_review.repo}:#{@pr_review.pr_number}"
    @job_running = Rails.cache.exist?("pr_analysis_running:#{@pr_review.repo}:#{@pr_review.pr_number}")

    if @pr_review.head_sha.present?
      cache_key = "pr_analysis/#{@pr_review.repo}/#{@pr_review.pr_number}/#{@pr_review.head_sha}"
      @analysis = Rails.cache.read(cache_key)
      if @analysis
        @cc_command = PrAnalysisService.new.claude_code_command(
          @pr_review,
          (@analysis[:risk_areas] || []).map { |r| r[:file] }.compact
        )
      end
    end

    if @analysis.nil? && !@job_running && @claude_configured && @github_configured
      PrAnalysisJob.perform_later(repo: @pr_review.repo, pr_number: @pr_review.pr_number)
      @job_running = true
    end
  end
end
