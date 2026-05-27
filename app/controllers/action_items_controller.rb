class ActionItemsController < ApplicationController
  before_action :set_item

  def approve
    case @item.action_type
    when "create_ticket", "delegate"
      developer = params[:developer_id].present? ? Developer.find(params[:developer_id]) : @item.suggested_developer

      if params[:create_issue] == "1"
        ActionQueueService.new.draft_ticket(@item) unless @item.draft_title.present?
        repo = params[:repo].presence || @item.suggested_repo
        if repo.present? && GitHubService.new.configured?
          result = GitHubService.new.create_issue(repo, title: @item.draft_title, body: @item.draft_body)
          @item.github_issue_url = result[:url]
        end
      end

      delegation = Delegation.create!(
        summary: @item.draft_title || @item.slack_topic.title,
        developer: developer,
        developer_name: developer&.name,
        urgency: @item.slack_topic.urgency&.capitalize,
        issue_type: @item.slack_topic.category,
        github_issue_url: @item.github_issue_url,
        slack_channel_id: @item.slack_thread.slack_channel_id,
        slack_thread_ts: @item.slack_thread.slack_thread_ts,
        status: "delegated",
        delegated_at: Time.current
      )
      @item.update!(status: "approved", approved_at: Time.current, delegation: delegation)
    when "acknowledge", "discuss"
      @item.update!(status: "approved", approved_at: Time.current)
    end

    @item.slack_topic.update!(status: "actioned")
    redirect_to root_path, notice: "Done."
  rescue => e
    redirect_to root_path, alert: "Failed: #{e.message}"
  end

  def dismiss
    @item.update!(status: "dismissed", dismissed_at: Time.current)
    @item.slack_topic.update!(status: "dismissed")
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("action_item_#{@item.id}") }
      format.html { redirect_to root_path, notice: "Dismissed." }
    end
  end

  def restore
    @item.update!(status: "pending", action_type: "acknowledge")
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("action_item_#{@item.id}") }
      format.html { redirect_to root_path, notice: "Restored." }
    end
  end

  private

  def set_item
    @item = ActionItem.find(params[:id])
  end
end
