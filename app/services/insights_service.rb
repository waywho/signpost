class InsightsService
  def alerts
    [
      *stale_oneones,
      *overloaded_developers,
      *overdue_commitments,
      *aging_prs,
      *unresolved_concerns,
      *upcoming_oneone_alerts
    ]
  end

  def patterns
    Setting.get("global", "daily_insights", default: []) || []
  end

  def refresh_patterns
    data = gather_pattern_data
    prompt = build_pattern_prompt(data)
    return [] if prompt.blank?

    response = ClaudeService.new.analyze(prompt, max_tokens: 1000, model: "claude-haiku-4-5-20251001")
    parsed = JSON.parse(response.to_s.gsub(/```json|```/, "").strip)
    Setting.set("global", "daily_insights", parsed)
    parsed
  rescue JSON::ParserError
    []
  end

  private

  def stale_oneones
    Developer.by_name.includes(:oneone_sessions).filter_map do |dev|
      last = dev.oneone_sessions.recent.first
      days = last ? (Date.current - last.session_date).to_i : nil
      if days.nil? && dev.created_at < 3.weeks.ago
        { type: "warning", icon: "ph-calendar-x", message: "#{dev.name} has never had a 1:1" }
      elsif days && days > 21
        { type: "warning", icon: "ph-calendar-x", message: "#{dev.name} hasn't had a 1:1 in #{days} days" }
      end
    end
  end

  def overloaded_developers
    Developer.by_name.includes(:delegations).filter_map do |dev|
      count = dev.delegations.active.count
      if count >= 5
        { type: "danger", icon: "ph-warning", message: "#{dev.name} has #{count} active delegations" }
      end
    end
  end

  def overdue_commitments
    grouped = Commitment.pending.where("due_date < ?", Date.current).group(:stakeholder).count
    grouped.filter_map do |stakeholder, count|
      name = stakeholder.presence || "No stakeholder"
      { type: "danger", icon: "ph-clock-countdown", message: "#{count} overdue commitment#{'s' if count > 1} to #{name}" }
    end
  end

  def aging_prs
    queue = begin
      GitHubService.new.pr_queue
    rescue
      return []
    end
    old = queue.select { |pr| pr[:created_at] < 3.days.ago }
    return [] if old.empty?
    [{ type: "warning", icon: "ph-git-pull-request", message: "#{old.size} PR#{'s' if old.size > 1} waiting for review > 3 days" }]
  end

  def unresolved_concerns
    Developer.by_name.includes(:developer_notes, :oneone_sessions).filter_map do |dev|
      recent_concerns = dev.developer_notes.where(note_type: "concern").where("created_at > ?", 1.month.ago)
      next if recent_concerns.empty?
      last_oneone = dev.oneone_sessions.recent.first
      if last_oneone.nil? || last_oneone.session_date < recent_concerns.minimum(:created_at).to_date
        { type: "warning", icon: "ph-flag", message: "#{dev.name} has #{recent_concerns.count} concern note#{'s' if recent_concerns.count > 1} with no follow-up 1:1" }
      end
    end
  end

  def gather_pattern_data
    topics = SlackTopic.where("created_at > ?", 30.days.ago).where.not(embedding: nil).includes(:slack_thread)
    {
      clusters: find_topic_clusters(topics.to_a),
      recurring: find_recurring_issues(topics),
      velocity: delegation_velocity
    }
  end

  def find_topic_clusters(topics)
    return [] if topics.size < 2

    clustered = []
    used = Set.new

    topics.each do |topic|
      next if used.include?(topic.id)

      similar = topics.reject { |t| t.id == topic.id || used.include?(t.id) }.select do |other|
        cosine_sim(topic.embedding, other.embedding) > 0.85
      end

      if similar.any?
        cluster = [topic] + similar
        cluster.each { |t| used.add(t.id) }
        clustered << {
          topics: cluster.map { |t| { id: t.id, title: t.title, channel: t.slack_thread&.slack_channel_name, urgency: t.urgency, date: t.created_at.to_date.to_s } },
          size: cluster.size
        }
      end
    end

    clustered.sort_by { |c| -c[:size] }
  end

  def find_recurring_issues(recent_topics)
    recent_topics.filter_map do |topic|
      next unless topic.embedding.present?

      older_matches = SlackTopic.where("created_at < ?", 30.days.ago)
                                .where(status: "actioned")
                                .where.not(embedding: nil)
                                .nearest_neighbors(:embedding, topic.embedding, distance: "cosine")
                                .first(3)
                                .select { |t| (1.0 - t.neighbor_distance) > 0.85 }

      next if older_matches.empty?

      {
        current: { id: topic.id, title: topic.title },
        matches: older_matches.map { |m| { title: m.title, date: m.created_at.to_date.to_s, similarity: (1.0 - m.neighbor_distance).round(2) } }
      }
    end
  end

  def delegation_velocity
    Developer.by_name.filter_map do |dev|
      done_last_30 = dev.delegations.where(status: "done").where("resolved_at > ?", 30.days.ago).count
      done_prev_30 = dev.delegations.where(status: "done").where(resolved_at: 60.days.ago..30.days.ago).count
      active = dev.delegations.active.count

      if done_prev_30 > 0 && done_last_30 < (done_prev_30 * 0.5)
        { name: dev.name, done_last_30: done_last_30, done_prev_30: done_prev_30, active: active, trend: "declining" }
      elsif done_last_30 > 0 && done_last_30 > (done_prev_30 * 1.5) && done_prev_30 > 0
        { name: dev.name, done_last_30: done_last_30, done_prev_30: done_prev_30, active: active, trend: "accelerating" }
      end
    end
  end

  def upcoming_oneone_alerts
    calendar = CalendarService.new
    return [] unless calendar.configured?

    calendar.upcoming_events(hours: 3).filter_map do |event|
      next unless event[:is_oneone] && event[:matched_developer]
      dev = event[:matched_developer]
      minutes = ((event[:start_time] - Time.current) / 60).to_i
      if minutes > 0 && minutes <= 180
        { type: "info", icon: "ph-calendar-check", message: "1:1 with #{dev.name} in #{minutes} minutes" }
      end
    end
  end

  def cosine_sim(a, b)
    return 0.0 unless a.present? && b.present?
    dot = a.zip(b).sum { |x, y| x * y }
    mag_a = Math.sqrt(a.sum { |x| x**2 })
    mag_b = Math.sqrt(b.sum { |x| x**2 })
    return 0.0 if mag_a.zero? || mag_b.zero?
    dot / (mag_a * mag_b)
  end

  def build_pattern_prompt(data)
    parts = []

    if data[:clusters].any?
      parts << "Topic clusters found (similar issues grouped by vector similarity):"
      data[:clusters].each do |c|
        titles = c[:topics].map { |t| "#{t[:title]} (#{t[:channel]}, #{t[:date]})" }.join("; ")
        parts << "- Cluster of #{c[:size]}: #{titles}"
      end
    end

    if data[:recurring].any?
      parts << "\nRecurring issues (new topics matching old resolved ones):"
      data[:recurring].each do |r|
        matches = r[:matches].map { |m| "#{m[:title]} (#{m[:date]}, #{(m[:similarity] * 100).round}% match)" }.join("; ")
        parts << "- '#{r[:current][:title]}' similar to: #{matches}"
      end
    end

    if data[:velocity].any?
      parts << "\nDelegation velocity changes:"
      data[:velocity].each do |v|
        parts << "- #{v[:name]}: #{v[:done_last_30]} completed (was #{v[:done_prev_30]}), #{v[:active]} active — #{v[:trend]}"
      end
    end

    return nil if parts.empty?

    <<~PROMPT
      You are analyzing a tech lead's team patterns for the past 30 days. The data below was detected using vector similarity (semantic matching) and delegation tracking.

      #{parts.join("\n")}

      Summarize each pattern as a clear, actionable one-sentence insight for the tech lead.

      Return a JSON array:
      [{"message": "insight text", "type": "cluster|recurring|velocity", "severity": "info|warning|danger"}]

      Only include genuinely notable patterns. Be specific — reference names, channels, and numbers. If nothing stands out, return [].
    PROMPT
  end
end
