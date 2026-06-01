class SlackPollJob < ApplicationJob
  queue_as :default

  # Default lookback if channel has never been polled
  INITIAL_LOOKBACK = 24.hours

  def perform
    mode = Setting.get("global", "slack_capture_mode", default: "both")
    return unless mode.in?(%w[poll both])

    emoji = Setting.get("global", "slack_brain_emoji", default: "brain")
    token = EncryptedSetting.get("credentials", "slack_bot_token")
    return unless token.present?
    slack = Slack::Web::Client.new(token: token)

    # 1. Scan messages in watched channels since last poll
    WatchedChannel.enabled.each do |channel|
      oldest = (channel.last_polled_at || INITIAL_LOOKBACK.ago).to_f.to_s
      poll_channel(slack, channel, oldest, emoji)
      channel.update_column(:last_polled_at, Time.current)
    rescue => e
      Rails.logger.error("SlackPollJob channel poll error on #{channel.channel_id}: #{e.message}")
    end

    # 2. Scan user's recent reactions for brain emoji (catches reactions on older messages)
    poll_user_reactions(emoji)
  rescue => e
    Rails.logger.error("SlackPollJob error: #{e.message}")
  end

  private

  def poll_channel(slack, channel, oldest, emoji)
    history = slack.conversations_history(channel: channel.channel_id, oldest: oldest, limit: 100)
    return unless history.messages

    history.messages.each do |message|
      next if skip_message?(message)

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

  def skip_message?(message)
    subtype = message["subtype"]

    # Channel join/leave, huddle, bot messages
    return true if subtype.in?(%w[
      channel_join channel_leave group_join group_leave
      huddle_thread sh_room_created sh_room_shared
      bot_message bot_add bot_remove reminder_add
      channel_topic channel_purpose channel_name
    ])

    # Bot users (reminders, integrations, etc.)
    return true if message["bot_id"].present? || message["bot_profile"].present?

    # GitHub PR review request notifications (handled by PR Reviews feature)
    text = message["text"].to_s
    return true if text.match?(/requested your review on|review requested/i)

    false
  end

  def poll_user_reactions(emoji)
    user_token = EncryptedSetting.get("credentials", "slack_user_token")
    return unless user_token.present?

    user_client = Slack::Web::Client.new(token: user_token)
    watched_ids = WatchedChannel.enabled.pluck(:channel_id).to_set

    response = user_client.reactions_list(count: 50, full: true)
    return unless response.items

    response.items.each do |item|
      message = item["message"]
      next unless message
      channel_id = message["channel"] || item.dig("channel", "id") || item["channel"]
      next unless channel_id
      next unless message["reactions"]&.any? { |r| r["name"] == emoji }

      thread_ts = message["thread_ts"] || message["ts"]
      next if SlackThread.exists?(slack_channel_id: channel_id, slack_thread_ts: thread_ts)

      SlackCaptureJob.perform_later(channel_id: channel_id, thread_ts: thread_ts, capture_reason: "brain_emoji")
    end
  rescue => e
    Rails.logger.error("SlackPollJob reactions scan error: #{e.message}")
  end
end
