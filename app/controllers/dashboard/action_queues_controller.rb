class Dashboard::ActionQueuesController < ApplicationController
  def show
    base = ActionItem.includes(:slack_topic, :slack_thread, :suggested_developer)
    @actionable_items = base.actionable.by_priority
    @discussion_items = base.discussions.by_priority
    @acknowledge_items = base.acknowledgements.by_priority
    @developers_for_select = Developer.by_name
    @github_repos = Setting.get("global", "github_repos", default: []) || []
  end
end
