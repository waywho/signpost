class SlackSearchService
  def initialize(embedding_service: nil)
    @embedder = embedding_service || EmbeddingService.new
  end

  def search(query:, threshold: nil, limit: 20, levels: nil, filters: {})
    threshold ||= Setting.get("global", "search_default_threshold", default: 0.75).to_f
    levels ||= %w[thread topic message]
    query_embedding = @embedder.embed(query)

    results = []
    results += search_threads(query_embedding, threshold, limit) if levels.include?("thread")
    results += search_topics(query_embedding, threshold, limit, filters) if levels.include?("topic")
    results += search_messages(query_embedding, threshold, limit) if levels.include?("message")

    results.sort_by { |r| -r[:similarity] }.first(limit)
  end

  private

  def search_threads(query_embedding, threshold, limit)
    SlackThread.uncompressed
      .nearest_neighbors(:embedding, query_embedding, distance: "cosine")
      .first(limit)
      .filter_map do |t|
        sim = 1.0 - t.neighbor_distance
        next if sim < threshold
        { type: "thread", similarity: sim.round(4),
          thread: { id: t.id, title: t.title, summary: t.summary, category: t.category, slack_url: t.slack_url, captured_at: t.captured_at } }
      end
  end

  def search_topics(query_embedding, threshold, limit, filters)
    scope = SlackTopic.joins(:slack_thread).includes(:slack_thread)
    scope = scope.where(category: filters[:category]) if filters[:category].present?
    scope = scope.where(urgency: filters[:urgency]) if filters[:urgency].present?

    scope.nearest_neighbors(:embedding, query_embedding, distance: "cosine")
      .first(limit)
      .filter_map do |topic|
        sim = 1.0 - topic.neighbor_distance
        next if sim < threshold
        { type: "topic", similarity: sim.round(4),
          topic: { id: topic.id, title: topic.title, summary: topic.summary, urgency: topic.urgency, category: topic.category, action: topic.action_recommendation },
          thread: { id: topic.slack_thread.id, title: topic.slack_thread.title, slack_url: topic.slack_thread.slack_url } }
      end
  end

  def search_messages(query_embedding, threshold, limit)
    SlackMessage.includes(:slack_thread)
      .nearest_neighbors(:embedding, query_embedding, distance: "cosine")
      .first(limit)
      .filter_map do |msg|
        sim = 1.0 - msg.neighbor_distance
        next if sim < threshold
        { type: "message", similarity: sim.round(4),
          message: { id: msg.id, content: msg.content, user_name: msg.user_name, message_ts: msg.message_ts },
          thread: { id: msg.slack_thread.id, title: msg.slack_thread.title, slack_url: msg.slack_thread.slack_url } }
      end
  end
end
