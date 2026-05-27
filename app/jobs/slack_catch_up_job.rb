class SlackCatchUpJob < ApplicationJob
  queue_as :default

  def perform
    mode = Setting.get("global", "slack_capture_mode", default: "both")
    return unless mode.in?(%w[socket both])

    oldest = 1.hour.ago.to_f.to_s
    emoji = Setting.get("global", "slack_brain_emoji", default: "brain")
    token = EncryptedSetting.get("credentials", "slack_bot_token")
    return unless token.present?
    slack = Slack::Web::Client.new(token: token)

    WatchedChannel.enabled.each do |channel|
      history = slack.conversations_history(channel: channel.channel_id, oldest: oldest, limit: 100)
      next unless history.messages

      history.messages.each do |message|
        next unless message["reactions"]&.any? { |r| r["name"] == emoji }
        thread_ts = message["thread_ts"] || message["ts"]
        SlackCaptureJob.perform_later(channel_id: channel.channel_id, thread_ts: thread_ts, capture_reason: "brain_emoji")
      end
    rescue => e
      Rails.logger.error("SlackCatchUpJob error on #{channel.channel_id}: #{e.message}")
    end
  end
end
