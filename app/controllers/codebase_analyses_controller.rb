class CodebaseAnalysesController < ApplicationController
  before_action :set_slack_thread
  before_action :set_analysis, only: %i[show]

  def create
    repo_paths = Setting.get("global", "repo_paths", default: {}) || {}
    repo_name = params[:repo_name]
    repo_path = repo_paths[repo_name]

    unless repo_path
      redirect_to slack_thread_path(@slack_thread), alert: "Unknown repo: #{repo_name}"
      return
    end

    analysis = @slack_thread.codebase_analyses.create!(repo_name:, repo_path:)
    CodebaseAnalysisJob.perform_later(analysis.id)
    redirect_to slack_thread_path(@slack_thread), notice: "Analysis started for #{repo_name}…"
  end

  def show
    @developers = Developer.by_name
    @github_repos = Setting.get("global", "github_repos", default: []) || []
    render layout: false
  end

  private

  def set_slack_thread
    @slack_thread = SlackThread.find(params[:slack_thread_id])
  end

  def set_analysis
    @analysis = @slack_thread.codebase_analyses.find(params[:id])
  end
end
