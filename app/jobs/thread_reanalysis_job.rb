class ThreadReanalysisJob < ApplicationJob
  queue_as :default

  def perform
    SlackThread.pending_reanalysis.find_each do |thread|
      ThreadAnalysisJob.perform_later(thread.id)
    end
  end
end
