class ThreadAnalysisJob < ApplicationJob
  queue_as :default

  def perform(slack_thread_id)
    thread = SlackThread.find(slack_thread_id)
    return unless thread.pending_reanalysis?

    threshold = Setting.get("global", "reanalysis_message_threshold", default: 3).to_i
    quiet_minutes = Setting.get("global", "reanalysis_quiet_minutes", default: 30).to_i

    new_count = thread.slack_messages.where("created_at > ?", thread.last_analyzed_at || 100.years.ago).count
    minutes_since = thread.last_analyzed_at ? ((Time.current - thread.last_analyzed_at) / 60) : 999

    return if new_count < threshold && minutes_since < quiet_minutes

    ThreadAnalysisService.new.analyze(thread)
    Turbo::StreamsChannel.broadcast_refresh_to(thread)
  end
end
