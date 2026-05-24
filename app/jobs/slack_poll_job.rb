class SlackPollJob < ApplicationJob
  queue_as :default

  def perform
    mode = Setting.get("global", "slack_capture_mode", default: "both")
    return unless mode.in?(%w[poll both])

    interval = Setting.get("global", "poll_interval_minutes", default: 15).to_i
    oldest = (Time.current - interval.minutes).to_f.to_s
    emoji = Setting.get("global", "slack_brain_emoji", default: "brain")
    slack = Slack::Web::Client.new

    WatchedChannel.enabled.each do |channel|
      poll_channel(slack, channel, oldest, emoji)
    rescue => e
      Rails.logger.error("SlackPollJob error on #{channel.channel_id}: #{e.message}")
    end
  end

  private

  def poll_channel(slack, channel, oldest, emoji)
    history = slack.conversations_history(channel: channel.channel_id, oldest: oldest, limit: 100)
    return unless history.messages

    history.messages.each do |message|
      thread_ts = message["thread_ts"] || message["ts"]

      if message["reactions"]&.any? { |r| r["name"] == emoji }
        SlackCaptureJob.perform_later(channel_id: channel.channel_id, thread_ts: thread_ts, capture_reason: "brain_emoji")
        next
      end

      if message["text"]&.include?("<@")
        SlackCaptureJob.perform_later(channel_id: channel.channel_id, thread_ts: thread_ts, capture_reason: "mention")
        next
      end

      if channel.capture_mode == "full_stream"
        SlackCaptureJob.perform_later(channel_id: channel.channel_id, thread_ts: thread_ts, capture_reason: "channel_stream")
      end
    end
  end
end
