class Dashboard::CalendarsController < ApplicationController
  def show
    service = CalendarService.new
    @today_events = service.configured? ? service.today_events : nil
  end
end
