class SlackThreads::DismissalsController < ApplicationController
  def create
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    @slack_thread.update!(status: "archived")
    redirect_to slack_threads_path, notice: "Dismissed."
  end
end
