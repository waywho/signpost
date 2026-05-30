class CodebaseAnalyses::DismissalsController < ApplicationController
  def destroy
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    @analysis = @slack_thread.codebase_analyses.find(params[:codebase_analysis_id])
    @analysis.destroy
    redirect_to slack_thread_path(@slack_thread), notice: "Analysis dismissed."
  end
end
