class SlackCaptureService
  def initialize(slack_client: nil, embedding_service: nil, noise_filter_service: nil)
    @slack = slack_client || Slack::Web::Client.new
    @embedder = embedding_service || EmbeddingService.new
    @noise_filter = noise_filter_service || NoiseFilterService.new
  end

  def capture(channel_id:, thread_ts:, capture_reason:)
    thread = find_or_create_thread(channel_id, thread_ts, capture_reason)
    replies = @slack.conversations_replies(channel: channel_id, ts: thread_ts, limit: 200)
    return thread unless replies.messages

    new_count = 0
    replies.messages.each do |message|
      next if thread.slack_messages.exists?(message_ts: message["ts"])
      next if message["text"].blank?
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

  def resolve_user_name(user_id)
    return unless user_id
    @slack.users_info(user: user_id).user.real_name
  rescue
    nil
  end
end
