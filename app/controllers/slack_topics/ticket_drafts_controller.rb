class SlackTopics::TicketDraftsController < ApplicationController
  def create
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    @topic = @slack_thread.slack_topics.find(params[:slack_topic_id])

    @topic.update!(drafting: true)
    TicketDraftJob.perform_later(@topic.id)

    redirect_to @slack_thread, notice: "Drafting ticket…"
  end
end
