class CodebaseAnalyses::NotificationsController < ApplicationController
  def create
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    @analysis = @slack_thread.codebase_analyses.find(params[:codebase_analysis_id])
    notify_thread
    redirect_to slack_thread_path(@slack_thread), notice: "Thread notified."
  end

  private

  def notify_thread
    slack = SlackService.new
    return unless slack.configured?

    channel = @slack_thread.slack_channel_id
    thread_ts = @slack_thread.slack_thread_ts
    parts = []
    parts << @analysis.github_issue_url if @analysis.github_issue_url.present?

    if parts.any?
      slack.post_message(channel:, thread_ts:, text: parts.join("\n"))
    else
      slack.add_reaction(channel:, timestamp: thread_ts, emoji: "eyes")
    end
  end
end
