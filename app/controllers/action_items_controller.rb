class ActionItemsController < ApplicationController
  def approve
    @item = ActionItem.find(params[:id])
    repo = params[:repo].presence || @item.suggested_repo
    developer = params[:developer_id].present? ? Developer.find(params[:developer_id]) : @item.suggested_developer

    if repo.present? && GitHubService.new.configured?
      result = GitHubService.new.create_issue(repo, title: @item.draft_title, body: @item.draft_body)
      @item.github_issue_url = result[:url]
    end

    delegation = Delegation.create!(
      summary: @item.draft_title,
      developer: developer,
      developer_name: developer&.name,
      urgency: @item.slack_topic.urgency&.capitalize,
      issue_type: @item.slack_topic.category,
      github_issue_url: @item.github_issue_url,
      slack_channel_id: @item.slack_thread.slack_channel_id,
      slack_thread_ts: @item.slack_thread.slack_thread_ts,
      handoff_message: @item.draft_body,
      status: "delegated",
      delegated_at: Time.current
    )

    @item.update!(status: "approved", approved_at: Time.current, delegation: delegation)
    @item.slack_topic.update!(status: "actioned")

    redirect_to root_path, notice: "Issue created and delegated to #{developer&.name || 'unassigned'}."
  end

  def dismiss
    @item = ActionItem.find(params[:id])
    @item.update!(status: "dismissed", dismissed_at: Time.current)
    @item.slack_topic.update!(status: "dismissed")
    redirect_to root_path, notice: "Dismissed."
  end
end
