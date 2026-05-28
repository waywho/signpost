class DashboardController < ApplicationController
  def show
    # Only render the shell with lazy turbo frames — no data loading
  end

  def action_queue
    base = ActionItem.includes(:slack_topic, :slack_thread, :suggested_developer)
    @actionable_items = base.actionable.by_priority
    @discussion_items = base.discussions.by_priority
    @acknowledge_items = base.acknowledgements.by_priority
    @ignored_count = ActionItem.ignored.count
    @ignored_items = ActionItem.ignored.includes(:slack_topic).by_priority if params[:show_ignored]
    @developers_for_select = Developer.by_name
    @github_repos = Setting.get("global", "github_repos", default: []) || []
  end

  def insights
    service = InsightsService.new
    @alerts = service.alerts
    @patterns = service.patterns
  end

  def calendar
    service = CalendarService.new
    @today_events = service.configured? ? service.today_events : nil
  end

  def team_overview
    @developers = Developer.by_name
  end

  def active_delegations
    @delegations = Delegation.active.by_urgency.includes(:developer)
  end

  def commitments
    @due = Commitment.due_soon.where("due_date >= ?", Date.current)
    @overdue = Commitment.pending.where("due_date < ?", Date.current).order(:due_date)
  end

  def pr_reviews
    @recent_pr_reviews = PrReview.recent.limit(5)
    @pr_queue = begin
      service = GitHubService.new
      service.configured? ? service.pr_queue : nil
    rescue => e
      Rails.logger.error("Dashboard PR queue failed: #{e.message}")
      nil
    end
  end

  def daily_log
    @daily_log = DailyLog.today
  end
end
