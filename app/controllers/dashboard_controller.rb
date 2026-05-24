class DashboardController < ApplicationController
  def show
    @developers         = Developer.by_name
    @active_delegations = Delegation.active.by_urgency.includes(:developer)
    @due_commitments    = Commitment.due_soon.where("due_date >= ?", Date.current)
    @overdue_commitments = Commitment.pending.where("due_date < ?", Date.current).order(:due_date)
    @recent_pr_reviews  = PrReview.recent.limit(5)
    @daily_log          = DailyLog.today
    @pr_queue = begin
      service = GitHubService.new
      service.configured? ? service.pr_queue : nil
    rescue => e
      Rails.logger.error("Dashboard PR queue failed: #{e.message}")
      nil
    end
  end
end
