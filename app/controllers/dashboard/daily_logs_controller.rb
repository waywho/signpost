class Dashboard::DailyLogsController < ApplicationController
  def show
    @daily_log = DailyLog.today
  end
end
