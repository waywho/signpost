class DashboardController < ApplicationController
  def show
    action_items_base = ActionItem.includes(:slack_topic, :slack_thread, :suggested_developer)
    @actionable_items = action_items_base.actionable.by_priority
    @discussion_items = action_items_base.discussions.by_priority
    @acknowledge_items = action_items_base.acknowledgements.by_priority
    @ignored_count = ActionItem.ignored.count
    @ignored_items = ActionItem.ignored.includes(:slack_topic).by_priority if params[:show_ignored]
    @developers_for_select = Developer.by_name

    insights = InsightsService.new
    @alerts = insights.alerts
    @patterns = insights.patterns

    calendar = CalendarService.new
    @today_events = calendar.configured? ? calendar.today_events : nil

    @developers         = Developer.by_name
    @active_delegations = Delegation.active.by_urgency.includes(:developer)
    @due_commitments    = Commitment.due_soon.where("due_date >= ?", Date.current)
    @overdue_commitments = Commitment.pending.where("due_date < ?", Date.current).order(:due_date)
    @recent_pr_reviews  = PrReview.recent.limit(5)
    @daily_log          = DailyLog.today
    @github_repos       = Setting.get("global", "github_repos", default: []) || []
    @pr_queue = begin
      service = GitHubService.new
      service.configured? ? service.pr_queue : nil
    rescue => e
      Rails.logger.error("Dashboard PR queue failed: #{e.message}")
      nil
    end
  end
end
