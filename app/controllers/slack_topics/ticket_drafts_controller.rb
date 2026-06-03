class SlackTopics::TicketDraftsController < ApplicationController
  def create
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    @topic = @slack_thread.slack_topics.find(params[:slack_topic_id])

    @topic.update!(drafting: true)
    TicketDraftJob.perform_later(@topic.id)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("topic_#{@topic.id}",
          partial: "slack_threads/topic", locals: { topic: @topic })
      end
      format.html { redirect_to @slack_thread, notice: "Drafting ticket…" }
    end
  end
end
