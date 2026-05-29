class CodebaseAnalysesController < ApplicationController
  before_action :set_slack_thread
  before_action :set_analysis, only: %i[show create_issue delegate notify dismiss]

  def create
    repo_paths = Setting.get("global", "repo_paths", default: {}) || {}
    repo_name = params[:repo_name]
    repo_path = repo_paths[repo_name]

    unless repo_path
      redirect_to slack_thread_path(@slack_thread), alert: "Unknown repo: #{repo_name}"
      return
    end

    analysis = @slack_thread.codebase_analyses.create!(repo_name:, repo_path:)
    CodebaseAnalysisJob.perform_later(analysis.id)
    redirect_to slack_thread_path(@slack_thread), notice: "Analysis started for #{repo_name}…"
  end

  def show
    @developers = Developer.by_name
    @github_repos = Setting.get("global", "github_repos", default: []) || []
    render layout: false
  end

  def create_issue
    repo = params[:repo].presence || @analysis.repo_name
    result = GitHubService.new.create_issue(repo, title: @analysis.draft_title, body: @analysis.draft_body)
    @analysis.update!(github_issue_url: result[:url])
    redirect_to slack_thread_path(@slack_thread), notice: "Issue ##{result[:number]} created."
  rescue => e
    redirect_to slack_thread_path(@slack_thread), alert: "Failed to create issue: #{e.message}"
  end

  def delegate
    developer = params[:developer_id].present? ? Developer.find(params[:developer_id]) : nil
    delegation = Delegation.create!(
      summary: @analysis.draft_title,
      developer:,
      developer_name: developer&.name,
      urgency: map_urgency,
      github_issue_url: @analysis.github_issue_url,
      slack_channel_id: @slack_thread.slack_channel_id,
      slack_thread_ts: @slack_thread.slack_thread_ts,
      status: "delegated",
      delegated_at: Time.current
    )
    @analysis.update!(delegation:)
    notify_thread(developer:) if params[:notify_thread] == "1"
    redirect_to slack_thread_path(@slack_thread), notice: "Delegated."
  end

  def notify
    notify_thread
    redirect_to slack_thread_path(@slack_thread), notice: "Thread notified."
  end

  def dismiss
    @analysis.destroy
    redirect_to slack_thread_path(@slack_thread), notice: "Analysis dismissed."
  end

  private

  def set_slack_thread
    @slack_thread = SlackThread.find(params[:slack_thread_id])
  end

  def set_analysis
    @analysis = @slack_thread.codebase_analyses.find(params[:id])
  end

  def map_urgency
    topic = @slack_thread.slack_topics.order(:urgency).first
    topic&.urgency || "medium"
  end

  def notify_thread(developer: nil)
    slack = SlackService.new
    return unless slack.configured?

    channel = @slack_thread.slack_channel_id
    thread_ts = @slack_thread.slack_thread_ts
    parts = []
    parts << "<@#{developer.slack_handle}> Can you take a look?" if developer&.slack_handle.present?
    parts << @analysis.github_issue_url if @analysis.github_issue_url.present?

    if parts.any?
      slack.post_message(channel:, thread_ts:, text: parts.join("\n"))
    else
      slack.add_reaction(channel:, timestamp: thread_ts, emoji: "eyes")
    end
  end
end
