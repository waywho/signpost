class SlackThreads::DelegationsController < ApplicationController
  def create
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    redirect_to new_delegation_path(delegation: {
      summary: @slack_thread.title.presence || @slack_thread.summary&.truncate(100) || "From Slack thread",
      slack_channel_id: @slack_thread.slack_channel_id,
      slack_thread_ts: @slack_thread.slack_thread_ts
    })
  end
end
