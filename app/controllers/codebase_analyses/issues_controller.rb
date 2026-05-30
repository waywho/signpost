class CodebaseAnalyses::IssuesController < ApplicationController
  def create
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    @analysis = @slack_thread.codebase_analyses.find(params[:codebase_analysis_id])
    repo = params[:repo].presence || @analysis.repo_name
    result = GitHubService.new.create_issue(repo, title: @analysis.draft_title, body: @analysis.draft_body)
    @analysis.update!(github_issue_url: result[:url])
    redirect_to slack_thread_path(@slack_thread), notice: "Issue ##{result[:number]} created."
  rescue => e
    redirect_to slack_thread_path(@slack_thread), alert: "Failed to create issue: #{e.message}"
  end
end
