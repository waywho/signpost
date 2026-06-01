class ThreadAnalysisService
  def initialize(embedding_service: nil, claude_service: nil)
    @embedder = embedding_service || EmbeddingService.new
    @claude = claude_service || ClaudeService.new
  end

  def analyze(thread)
    messages = thread.slack_messages.chronological
    return if messages.empty?

    content = messages.map { |m| "[#{m.user_name || m.user_id}] #{m.content}" }.join("\n")

    analysis = analyze_with_claude(content)

    thread_embedding = @embedder.embed(analysis[:summary])
    thread.update!(
      title: analysis[:title],
      summary: analysis[:summary],
      category: analysis[:category],
      keywords: analysis[:keywords],
      participants: messages.filter_map(&:user_name).uniq,
      embedding: thread_embedding,
      last_analyzed_at: Time.current,
      pending_reanalysis: false
    )

    upsert_topics(thread, analysis[:topics], messages)
  end

  private

  def analyze_with_claude(content)
    prompt = <<~PROMPT
      Analyze this Slack thread for a tech lead. Identify distinct, actionable topics.

      CRITICAL RULES for topic extraction:
      - Only create SEPARATE topics when they have genuinely different root causes, different owners, or need different actions.
      - Related aspects of the SAME issue (e.g. "bug exists" + "bug affects users" + "fix for bug") are ONE topic, not three.
      - Symptoms and causes of the same problem are ONE topic.
      - A discussion about how to fix something and the bug itself are ONE topic.
      - When in doubt, MERGE into fewer topics. One well-described topic is better than three overlapping ones.
      - Prefer 1-2 topics per thread. Only extract 3+ if the thread genuinely covers unrelated issues.

      Thread:
      #{content.truncate(4000)}

      Reply in this exact JSON format (no markdown fences, just raw JSON):
      {
        "title": "short thread title",
        "summary": "2-3 sentence summary of the whole thread",
        "category": "architecture|stakeholder|team_decision|incident|other",
        "keywords": ["keyword1", "keyword2"],
        "topics": [
          {
            "title": "short topic title",
            "summary": "1-3 sentence description of this specific issue",
            "category": "bug|feature|question|incident|architecture|process|other",
            "urgency": "critical|high|medium|low",
            "action": "delegate|create_ticket|acknowledge|discuss|ignore",
            "related_message_indices": [0, 1, 3]
          }
        ]
      }

      related_message_indices are 0-based indices into the message list above.
      Always extract at least one topic. If the thread has one clear topic, return one.
    PROMPT

    raw = @claude.analyze(prompt, max_tokens: 1000)
    json_str = raw.gsub(/\A```json\s*/, "").gsub(/```\s*\z/, "").strip
    JSON.parse(json_str).deep_symbolize_keys
  rescue JSON::ParserError
    { title: "Thread", summary: content.truncate(200), category: "other", keywords: [], topics: [] }
  end

  def upsert_topics(thread, topic_data, messages)
    return if topic_data.blank?

    existing_topics = thread.slack_topics.to_a

    topic_data.each do |td|
      topic_embedding = @embedder.embed(td[:summary])

      matched = existing_topics.find do |et|
        et.embedding && cosine_similarity(et.embedding, topic_embedding) > 0.85
      end

      topic = if matched
        matched.update!(title: td[:title], summary: td[:summary], category: td[:category],
                        urgency: td[:urgency], action_recommendation: td[:action],
                        embedding: topic_embedding)
        matched
      else
        thread.slack_topics.create!(
          title: td[:title], summary: td[:summary], category: td[:category],
          urgency: td[:urgency], action_recommendation: td[:action],
          embedding: topic_embedding, status: "open"
        )
      end

      if td[:related_message_indices].present?
        message_list = messages.to_a
        td[:related_message_indices].each do |idx|
          msg = message_list[idx]
          next unless msg
          SlackTopicMessage.find_or_create_by!(slack_topic: topic, slack_message: msg)
        end
      end

      ActionQueueService.new.process(topic) if topic.action_recommendation.present?
    end
  end

  def cosine_similarity(a, b)
    dot = a.zip(b).sum { |x, y| x * y }
    mag_a = Math.sqrt(a.sum { |x| x**2 })
    mag_b = Math.sqrt(b.sum { |x| x**2 })
    return 0.0 if mag_a.zero? || mag_b.zero?
    dot / (mag_a * mag_b)
  end
end
