class PrReviewsController < ApplicationController
  def index
    @pr_queue = begin
      service = GitHubService.new
      service.configured? ? service.pr_queue : nil
    rescue => e
      Rails.logger.error("PR queue fetch failed: #{e.message}")
      nil
    end

    @pr_reviews = PrReview.recent
    @pr_reviews = @pr_reviews.where(repo: params[:repo]) if params[:repo].present?
    @pr_reviews = @pr_reviews.where(recommendation: params[:recommendation]) if params[:recommendation].present?
    @pr_reviews = @pr_reviews.where(risk_level: params[:risk_level]) if params[:risk_level].present?
  end

  def show
    @pr_review = PrReview.find(params[:id])
  end

  def new
    @pr_review = PrReview.new(
      repo: params[:repo],
      pr_number: params[:pr_number],
      pr_title: params[:pr_title],
      pr_author: params[:pr_author],
      reviewed_at: Time.current
    )
  end

  def create
    @pr_review = PrReview.new(pr_review_params)
    if @pr_review.save
      redirect_to @pr_review, notice: "Review logged."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def pr_review_params
    params.require(:pr_review).permit(
      :pr_number, :repo, :pr_title, :pr_author,
      :recommendation, :risk_level, :summary, :draft_comment,
      :files_changed, :additions, :deletions, :reviewed_at
    )
  end
end
