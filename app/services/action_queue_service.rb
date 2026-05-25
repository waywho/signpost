class ActionQueueService
  def initialize(ticket_draft_service: nil, assignee_suggestion_service: nil)
    @drafter = ticket_draft_service || TicketDraftService.new
    @suggester = assignee_suggestion_service || AssigneeSuggestionService.new
  end

  def process(topic)
    return if ActionItem.exists?(slack_topic_id: topic.id)
    return unless topic.action_recommendation.in?(%w[delegate create_ticket])
    return unless topic.status == "open"

    draft = @drafter.draft(topic)
    suggestion = @suggester.suggest(topic)
    repos = Setting.get("global", "github_repos", default: [])
    related = find_related(topic)

    ActionItem.create!(
      slack_topic: topic,
      slack_thread: topic.slack_thread,
      priority: compute_priority(topic),
      status: "pending",
      draft_title: draft[:title],
      draft_body: draft[:body],
      suggested_developer: suggestion&.dig(:developer),
      suggestion_reason: suggestion&.dig(:reason),
      suggested_repo: draft[:suggested_repo] || repos&.first,
      related_items: related
    )
  end

  private

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
