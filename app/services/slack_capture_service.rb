class SlackCaptureService
  def initialize(slack_client: nil, embedding_service: nil, noise_filter_service: nil)
    @slack = slack_client || Slack::Web::Client.new(token: EncryptedSetting.get("credentials", "slack_bot_token"))
    @embedder = embedding_service || EmbeddingService.new
    @noise_filter = noise_filter_service || NoiseFilterService.new
  end

  def capture(channel_id:, thread_ts:, capture_reason:)
    replies = @slack.conversations_replies(channel: channel_id, ts: thread_ts, limit: 200)
    return nil unless replies.messages

    # Filter out noise messages before any DB writes or embeddings
    real_messages = replies.messages.reject { |m| skip_noise?(m) || m["text"].blank? }
    return nil if real_messages.empty?

    thread = find_or_create_thread(channel_id, thread_ts, capture_reason)

    new_count = 0
    real_messages.each do |message|
      next if thread.slack_messages.exists?(message_ts: message["ts"])
      next if @noise_filter.noise?(message["text"])

      embedding = @embedder.embed(message["text"])
      thread.slack_messages.create!(
        message_ts: message["ts"],
        user_id: message["user"],
        user_name: resolve_user_name(message["user"]),
        content: message["text"],
        embedding: embedding,
        mentioned_users: message["text"].scan(/<@(\w+)>/).flatten,
        message_ts_at: Time.at(message["ts"].to_f)
      )
      new_count += 1
    rescue ActiveRecord::RecordNotUnique
      next
    end

    if new_count > 0
      thread.update!(pending_reanalysis: true)
      ThreadAnalysisJob.perform_later(thread.id)
    end

    thread
  end

  private

  def find_or_create_thread(channel_id, thread_ts, capture_reason)
    thread = SlackThread.find_by(slack_channel_id: channel_id, slack_thread_ts: thread_ts)
    return thread if thread

    channel_name = begin
      @slack.conversations_info(channel: channel_id).channel.name
    rescue
      nil
    end

    SlackThread.create!(
      slack_channel_id: channel_id,
      slack_thread_ts: thread_ts,
      slack_channel_name: channel_name,
      capture_reason: capture_reason,
      slack_url: "https://slack.com/archives/#{channel_id}/p#{thread_ts.delete('.')}",
      captured_at: Time.current,
      status: "new"
    )
  end

  def skip_noise?(message)
    subtype = message["subtype"]
    return true if subtype.in?(%w[channel_join channel_leave group_join group_leave huddle_thread sh_room_created sh_room_shared bot_message bot_add bot_remove reminder_add channel_topic channel_purpose channel_name])
    return true if message["bot_id"].present? || message["bot_profile"].present?
    return true if message["text"].to_s.match?(/requested your review on|review requested/i)
    false
  end

  def resolve_user_name(user_id)
    return unless user_id
    @slack.users_info(user: user_id).user.real_name
  rescue
    nil
  end
end
