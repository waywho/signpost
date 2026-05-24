class SlackSocketListener
  def self.start
    mode = Setting.get("global", "slack_capture_mode", default: "both")
    unless mode.in?(%w[socket both])
      puts "Capture mode is '#{mode}', Socket Mode not enabled. Exiting."
      return
    end

    bot_token = EncryptedSetting.get("credentials", "slack_bot_token")
    unless bot_token
      puts "Missing slack_bot_token in encrypted settings. Exiting."
      return
    end

    client = Slack::RealTime::Client.new(token: bot_token)
    emoji = Setting.get("global", "slack_brain_emoji", default: "brain")
    watched_ids = WatchedChannel.enabled.pluck(:channel_id).to_set

    client.on :reaction_added do |data|
      if data.reaction == emoji
        SlackCaptureJob.perform_later(
          channel_id: data.item.channel,
          thread_ts: data.item.ts,
          capture_reason: "brain_emoji"
        )
      end
    end

    client.on :message do |data|
      next if data.subtype
      channel_id = data.channel
      thread_ts = data.thread_ts || data.ts

      if data.text&.include?("<@")
        SlackCaptureJob.perform_later(channel_id: channel_id, thread_ts: thread_ts, capture_reason: "mention")
        next
      end

      if watched_ids.include?(channel_id)
        channel = WatchedChannel.find_by(channel_id: channel_id)
        if channel&.capture_mode == "full_stream"
          SlackCaptureJob.perform_later(channel_id: channel_id, thread_ts: thread_ts, capture_reason: "channel_stream")
        end
      end
    end

    puts "Connecting to Slack Socket Mode..."
    client.start!
  end
end
