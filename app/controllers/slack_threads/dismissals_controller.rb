class SlackThreads::DismissalsController < ApplicationController
  def create
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    @slack_thread.update!(status: "archived")
    @slack_thread.slack_topics.open.each do |topic|
      topic.update!(status: "dismissed")
      topic.action_items.pending.update_all(status: "dismissed", actioned_at: Time.current)
    end
    redirect_to slack_threads_path, notice: "Dismissed."
  end
end
