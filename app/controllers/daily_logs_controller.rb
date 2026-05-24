class DailyLogsController < ApplicationController
  def create
    @log = DailyLog.today
    if @log.update(log_params)
      redirect_to root_path, notice: "Log saved."
    else
      redirect_to root_path, alert: "Could not save log."
    end
  end

  def update
    @log = DailyLog.find(params[:id])
    if @log.update(log_params)
      redirect_to root_path, notice: "Log updated."
    else
      redirect_to root_path, alert: "Could not update log."
    end
  end

  private

  def log_params
    params.require(:daily_log).permit(:eod_notes, tomorrow_priorities: [])
  end
end
