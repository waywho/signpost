class SlackThreads::TriagesController < ApplicationController
  def create
    @slack_thread = SlackThread.find(params[:slack_thread_id])

    if @slack_thread.slack_messages.any?
      ThreadAnalysisJob.perform_later(@slack_thread.id)
      redirect_to @slack_thread, notice: "Re-triage started."
    elsif @slack_thread.slack_channel_id.present? && @slack_thread.slack_thread_ts.present?
      SlackCaptureJob.perform_later(
        channel_id: @slack_thread.slack_channel_id,
        thread_ts: @slack_thread.slack_thread_ts,
        capture_reason: "manual"
      )
      redirect_to @slack_thread, notice: "Fetching messages and triaging..."
    else
      redirect_to @slack_thread, alert: "No messages to analyze."
    end
  end
end
