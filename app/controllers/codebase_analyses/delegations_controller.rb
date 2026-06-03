class CodebaseAnalyses::DelegationsController < ApplicationController
  def create
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    @analysis = @slack_thread.codebase_analyses.find(params[:codebase_analysis_id])
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

  private

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
    parts << "#{developer.slack_mention} Can you take a look?" if developer&.slack_mention
    parts << @analysis.github_issue_url if @analysis.github_issue_url.present?

    if parts.any?
      slack.post_message(channel:, thread_ts:, text: parts.join("\n"))
    else
      slack.add_reaction(channel:, timestamp: thread_ts, emoji: "eyes")
    end
  end
end
