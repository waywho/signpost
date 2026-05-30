class Delegations::IssuesController < ApplicationController
  def create
    @delegation = Delegation.find(params[:delegation_id])
    repo = params[:repo]

    if repo.blank?
      redirect_to @delegation, alert: "Select a repo."
      return
    end

    result = GitHubService.new.create_issue(
      repo,
      title: @delegation.summary,
      body: @delegation.handoff_message.presence || @delegation.summary
    )

    @delegation.update!(github_issue_url: result[:url])
    redirect_to @delegation, notice: "GitHub issue ##{result[:number]} created."
  rescue => e
    redirect_to @delegation, alert: "Failed to create issue: #{e.message}"
  end
end
