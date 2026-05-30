class Dashboard::InsightsController < ApplicationController
  def show
    service = InsightsService.new
    @alerts = service.alerts
    @patterns = service.patterns
  end
end
