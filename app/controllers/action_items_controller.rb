class ActionItemsController < ApplicationController
  before_action :set_item

  TOPIC_STATUS_MAP = {
    "dismissed" => "dismissed",
    "resolved" => "actioned",
    "pending" => "open"
  }.freeze

  def update
    status = params[:status]
    @item.update!(status:, actioned_at: Time.current)
    topic_status = TOPIC_STATUS_MAP.fetch(status, "actioned")
    @item.slack_topic.update!(status: topic_status)
    archive_thread_if_no_open_topics

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("action_item_#{@item.id}") }
      format.html { redirect_to root_path, notice: "#{status.capitalize}." }
    end
  rescue => e
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("action_item_#{@item.id}",
          partial: "action_items/error", locals: { item: @item, message: e.message })
      end
      format.html { redirect_to root_path, alert: "Failed: #{e.message}" }
    end
  end

  private

  def set_item
    @item = ActionItem.find(params[:id])
  end

  def archive_thread_if_no_open_topics
    thread = @item.slack_thread
    return if thread.archived?
    thread.update!(status: "archived") unless thread.slack_topics.open.exists?
  end
end
