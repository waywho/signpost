class DelegationsController < ApplicationController
  before_action :set_delegation, only: [:show, :edit, :update, :destroy, :create_issue]

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
    @delegation = Delegation.new
    @developers = Developer.by_name
  end

  def create
    @delegation = Delegation.new(delegation_params)
    @delegation.delegated_at ||= Time.current
    if @delegation.save
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

  def create_issue
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

  def destroy
    @delegation.destroy
    redirect_to delegations_path, notice: "Delegation removed.", status: :see_other
  end

  private

  def set_delegation
    @delegation = Delegation.find(params[:id])
  end

  def delegation_params
    params.require(:delegation).permit(
      :summary, :urgency, :issue_type, :handoff_message,
      :codebase_context, :developer_id, :developer_name,
      :status, :github_issue_url
    )
  end
end
