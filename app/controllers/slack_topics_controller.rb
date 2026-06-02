class SlackTopicsController < ApplicationController
  def update
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    @topic = @slack_thread.slack_topics.find(params[:id])

    @topic.update!(status: params[:status])
    sync_action_items

    redirect_to @slack_thread, notice: "Topic #{params[:status]}."
  rescue => e
    redirect_to @slack_thread, alert: "Failed: #{e.message}"
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
