class DelegationsController < ApplicationController
  before_action :set_delegation, only: [:show, :edit, :update, :destroy]

  def index
    @delegations = Delegation.includes(:developer)
    if params[:status].present?
      @delegations = @delegations.where(status: params[:status])
    else
      @delegations = @delegations.active
    end
    @delegations = @delegations.by_urgency.order(delegated_at: :desc)
  end

  def show; end

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
