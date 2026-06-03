class DelegationsController < ApplicationController
  before_action :set_delegation, only: [ :show, :edit, :update, :destroy ]

  def index
    @delegations = Delegation.includes(:developer)
    if params[:status].present?
      @delegations = @delegations.where(status: params[:status])
    else
      @delegations = @delegations.active
    end
    @delegations = @delegations.by_urgency.order(delegated_at: :desc)
  end

  def show
    @github_repos = Setting.get("global", "github_repos", default: []) || []
    @github_configured = GitHubService.new.configured?
  end

  def new
    @delegation = Delegation.new(thread_params || (params[:delegation] ? delegation_params : {}))
    @developers = Developer.by_name
  end

  def create
    @delegation = Delegation.new(delegation_params)
    @delegation.delegated_at ||= Time.current
    if @delegation.save
      action_source_topic
      redirect_to @delegation, notice: "Delegation created."
    else
      @developers = Developer.by_name
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @developers = Developer.by_name
  end

  def update
    if @delegation.update(delegation_params)
      redirect_to @delegation, notice: "Delegation updated."
    else
      @developers = Developer.by_name
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @delegation.destroy
    redirect_to delegations_path, notice: "Delegation removed.", status: :see_other
  end

  private

  def set_delegation
    @delegation = Delegation.find(params[:id])
  end

  def action_source_topic
    return unless params[:slack_topic_id].present?
    topic = SlackTopic.find_by(id: params[:slack_topic_id])
    return unless topic
    @delegation.update!(slack_topic: topic) if @delegation.slack_topic_id.nil?
    return unless topic.open?
    topic.update!(status: "actioned")
    topic.action_items.pending.update_all(status: "actioned", actioned_at: Time.current)
  end

  def thread_params
    return unless params[:thread_id]

    thread = SlackThread.find(params[:thread_id])
    topic = thread.slack_topics.find_by(id: params[:slack_topic_id])

    {
      summary: topic&.title.presence || thread.title.presence || thread.summary&.truncate(100) || "From Slack thread",
      slack_channel_id: thread.slack_channel_id,
      slack_thread_ts: thread.slack_thread_ts,
      urgency: topic&.urgency,
      issue_type: topic&.category
    }.compact_blank
  end

  def delegation_params
    params.require(:delegation).permit(
      :summary, :urgency, :issue_type, :handoff_message,
      :codebase_context, :developer_id, :developer_name,
      :status, :github_issue_url,
      :slack_channel_id, :slack_thread_ts
    )
  end
end
