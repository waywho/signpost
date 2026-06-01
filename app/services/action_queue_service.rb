class ActionQueueService
  def initialize(ticket_draft_service: nil, assignee_suggestion_service: nil, noise_filter_service: nil)
    @drafter = ticket_draft_service || TicketDraftService.new
    @suggester = assignee_suggestion_service || AssigneeSuggestionService.new
    @noise_filter = noise_filter_service || NoiseFilterService.new
  end

  def process(topic)
    return if ActionItem.exists?(slack_topic_id: topic.id)
    return unless topic.status == "open"
    return unless topic.action_recommendation.in?(ActionItem.action_types.keys)
    return if @noise_filter.noise?("#{topic.title} #{topic.summary}")

    action_type = topic.action_recommendation
    attrs = {
      slack_topic: topic,
      slack_thread: topic.slack_thread,
      priority: compute_priority(topic),
      status: "pending",
      action_type: action_type
    }

    case action_type
    when "create_ticket"
      draft = @drafter.draft(topic)
      suggestion = @suggester.suggest(topic)
      attrs.merge!(
        draft_title: draft[:title],
        draft_body: draft[:body],
        suggested_developer: suggestion&.dig(:developer),
        suggestion_reason: suggestion&.dig(:reason),
        suggested_repo: draft[:suggested_repo] || default_repo,
        related_items: find_related(topic)
      )
    when "delegate"
      suggestion = @suggester.suggest(topic)
      attrs.merge!(
        suggested_developer: suggestion&.dig(:developer),
        suggestion_reason: suggestion&.dig(:reason),
        related_items: find_related(topic)
      )
    when "ignore"
      attrs[:status] = "ignored"
    end

    ActionItem.create!(attrs)
  end

  def draft_ticket(action_item)
    return if action_item.draft_title.present?
    draft = @drafter.draft(action_item.slack_topic)
    action_item.update!(
      draft_title: draft[:title],
      draft_body: draft[:body],
      suggested_repo: draft[:suggested_repo] || action_item.suggested_repo || default_repo
    )
  end

  def recompute_priorities
    ActionItem.pending.find_each do |item|
      item.update!(priority: compute_priority(item.slack_topic))
    end
  end

  private

  def default_repo
    repos = Setting.get("global", "github_repos", default: [])
    repos&.first
  end

  def find_related(topic)
    return [] unless topic.embedding.present?

    results = SlackSearchService.new.search(
      query: topic.summary,
      threshold: 0.8,
      limit: 5,
      levels: %w[topic thread]
    )

    results.reject { |r|
      (r[:type] == "topic" && r.dig(:topic, :id) == topic.id) ||
      (r[:type] == "thread" && r.dig(:thread, :id) == topic.slack_thread_id)
    }.first(3).map do |r|
      {
        type: r[:type],
        similarity: r[:similarity],
        title: r[:type] == "topic" ? r.dig(:topic, :title) : r.dig(:thread, :title),
        thread_id: r.dig(:thread, :id),
        thread_url: r.dig(:thread, :slack_url)
      }
    end
  rescue => e
    Rails.logger.error("ActionQueueService related search error: #{e.message}")
    []
  end

  def compute_priority(topic)
    base = case topic.urgency
           when "critical" then 0
           when "high" then 10
           when "medium" then 20
           when "low" then 30
           else 25
           end
    age_hours = (Time.current - topic.created_at) / 1.hour
    [base - age_hours.to_i, 0].max
  end
end
