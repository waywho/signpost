class OneoneSessionsController < ApplicationController
  before_action :set_developer
  before_action :set_session, only: [:show]

  def new
    @oneone_session = @developer.oneone_sessions.build(session_date: Date.today)
  end

  def create
    @oneone_session = @developer.oneone_sessions.build(session_params)
    if @oneone_session.save
      redirect_to developer_oneone_session_path(@developer, @oneone_session), notice: "1:1 session saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  private

  def set_developer
    @developer = Developer.find(params[:developer_id])
  end

  def set_session
    @oneone_session = @developer.oneone_sessions.find(params[:id])
  end

  def session_params
    params.require(:oneone_session).permit(
      :session_date, :discussed, :wins, :challenges,
      :growth, :action_items, :private_notes, :summary
    )
  end
end
