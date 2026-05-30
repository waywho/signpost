class SlackTopics::DelegationsController < ApplicationController
  def create
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    @topic = @slack_thread.slack_topics.find(params[:slack_topic_id])
    redirect_to new_delegation_path(delegation: {
      summary: @topic.title,
      slack_channel_id: @slack_thread.slack_channel_id,
      slack_thread_ts: @slack_thread.slack_thread_ts,
      urgency: @topic.urgency,
      issue_type: @topic.category
    })
  end
end
