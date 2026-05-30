class SlackThreads::AcknowledgementsController < ApplicationController
  def create
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    begin
      SlackService.new.add_reaction(
        channel: @slack_thread.slack_channel_id,
        timestamp: @slack_thread.slack_thread_ts,
        emoji: Setting.get("global", "slack_brain_emoji", default: "brain")
      )
    rescue => e
      Rails.logger.error("Acknowledge failed: #{e.message}")
    end
    @slack_thread.update!(status: "triaged")
    redirect_to slack_threads_path, notice: "Acknowledged."
  end
end
