class InsightsRefreshJob < ApplicationJob
  queue_as :default

  def perform
    InsightsService.new.refresh_patterns
  end
end
