class SlackTopicsController < ApplicationController
  def update
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    @topic = @slack_thread.slack_topics.find(params[:id])

    @topic.update!(status: params[:status])
    sync_action_items

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("topic_#{@topic.id}",
          partial: "slack_threads/topic", locals: { topic: @topic })
      end
      format.html { redirect_to @slack_thread, notice: "Topic #{params[:status]}." }
    end
  rescue => e
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("topic_#{@topic.id}",
          html: content_tag(:div, e.message, id: "topic_#{@topic.id}", class: "alert alert--negative mbe-2"))
      end
      format.html { redirect_to @slack_thread, alert: "Failed: #{e.message}" }
    end
  end

  private

  def sync_action_items
    case @topic.status
    when "dismissed"
      @topic.action_items.pending.update_all(status: "dismissed", actioned_at: Time.current)
    when "actioned"
      @topic.action_items.pending.update_all(status: "actioned", actioned_at: Time.current)
    end
  end
end
