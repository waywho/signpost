class DevelopersController < ApplicationController
  before_action :set_developer, only: [:show, :edit, :update, :destroy]

  def index
    @developers = Developer.by_name.includes(:developer_notes, :oneone_sessions)
  end

  def show
    @developer_note = DeveloperNote.new
    @notes = @developer.developer_notes.recent
    @oneone_sessions = @developer.oneone_sessions.recent
    @claude_configured = ClaudeService.new.configured?
    @github_activities = if @developer.github_handle.present? && GitHubService.new.configured?
      begin
        GitHubService.new.developer_activity(@developer.github_handle)
      rescue => e
        Rails.logger.error("GitHub activity fetch failed: #{e.message}")
        []
      end
    else
      []
    end
  end

  def new
    @developer = Developer.new
  end

  def create
    @developer = Developer.new(developer_params)
    if @developer.save
      redirect_to @developer, notice: "Developer added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @developer.update(developer_params)
      redirect_to @developer, notice: "Developer updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @developer.destroy
    redirect_to developers_path, notice: "Developer removed."
  end

  private

  def set_developer
    @developer = Developer.find(params[:id])
  end

  def developer_params
    params.require(:developer).permit(
      :name, :role, :level, :github_handle, :slack_handle,
      :color, :joined_team, :career_goals, :strengths,
      :growth_areas, :private_notes, skills: []
    )
  end
end
