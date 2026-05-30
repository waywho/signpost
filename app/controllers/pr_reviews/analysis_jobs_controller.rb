class PrReviews::AnalysisJobsController < ApplicationController
  def create
    PrAnalysisJob.perform_later(repo: params[:repo], pr_number: params[:pr_number].to_i)
    redirect_back fallback_location: pr_reviews_path, notice: "Analysis queued for ##{params[:pr_number]}. Come back shortly."
  end
end
