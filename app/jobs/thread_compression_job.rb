class ThreadCompressionJob < ApplicationJob
  queue_as :default

  def perform
    months = Setting.get("global", "compression_after_months", default: 6).to_i
    cutoff = months.months.ago

    SlackThread.uncompressed
      .where("captured_at < ?", cutoff)
      .where.not(id: SlackTopic.open.select(:slack_thread_id))
      .find_each do |thread|
        SlackTopicMessage.where(slack_topic_id: thread.slack_topic_ids).delete_all
        thread.slack_messages.delete_all
        thread.update!(compressed: true)
      rescue => e
        Rails.logger.error("ThreadCompressionJob error on #{thread.id}: #{e.message}")
      end
  end
end
