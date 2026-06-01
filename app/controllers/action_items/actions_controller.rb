class ActionItems::ActionsController < ApplicationController
  def create
    @item = ActionItem.find(params[:action_item_id])

    case @item.action_type
    when "create_ticket", "delegate"
      developer = if params[:developer_id].present?
        Developer.find(params[:developer_id])
      elsif !params.key?(:developer_id)
        @item.suggested_developer
      end
      ticket_url = resolve_ticket_url

      delegation = Delegation.create!(
        summary: @item.draft_title || @item.slack_topic.title,
        developer:,
        developer_name: developer&.name,
        urgency: @item.slack_topic.urgency,
        issue_type: @item.slack_topic.category,
        github_issue_url: ticket_url,
        slack_channel_id: @item.slack_thread.slack_channel_id,
        slack_thread_ts: @item.slack_thread.slack_thread_ts,
        status: "delegated",
        delegated_at: Time.current
      )
      @item.update!(status: "actioned", actioned_at: Time.current, delegation:, github_issue_url: ticket_url)
      notify_thread(developer:, ticket_url:) if params[:notify_thread] == "1"
    when "acknowledge", "discuss"
      @item.update!(status: "actioned", actioned_at: Time.current)
    end

    @item.slack_topic.update!(status: "actioned")
    redirect_to root_path, notice: "Done."
  rescue => e
    redirect_to root_path, alert: "Failed: #{e.message}"
  end

  private

  def resolve_ticket_url
    if params[:existing_issue_url].present?
      params[:existing_issue_url].strip
    elsif params[:create_issue] == "1"
      create_github_issue
    end
  end

  def create_github_issue
    ActionQueueService.new.draft_ticket(@item) unless @item.draft_title.present?
    repo = params[:repo].presence || @item.suggested_repo
    return unless repo.present? && GitHubService.new.configured?

    result = GitHubService.new.create_issue(repo, title: @item.draft_title, body: @item.draft_body)
    result[:url]
  end

  def notify_thread(developer:, ticket_url:)
    slack = SlackService.new
    return unless slack.configured?

    channel = @item.slack_thread.slack_channel_id
    thread_ts = @item.slack_thread.slack_thread_ts

    parts = []
    if developer&.slack_handle.present?
      parts << "<@#{developer.slack_handle}> Can you take a look?"
    end
    parts << ticket_url if ticket_url.present?

    if parts.empty?
      slack.add_reaction(channel:, timestamp: thread_ts, emoji: "eyes")
    else
      if developer&.slack_handle.blank? && ticket_url.present?
        parts.unshift("A ticket is created:")
      end
      slack.post_message(channel:, thread_ts:, text: parts.join("\n"))
    end
  end
end
