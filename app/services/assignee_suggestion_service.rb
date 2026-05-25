class AssigneeSuggestionService
  def suggest(topic)
    developers = Developer.by_name.includes(:delegations)
    return nil if developers.empty?

    scored = developers.map do |dev|
      { developer: dev, score: score_developer(dev, topic), reason: build_reason(dev, topic) }
    end.sort_by { |s| -s[:score] }

    best = scored.first
    { developer: best[:developer], reason: best[:reason] }
  end

  private

  def score_developer(dev, topic)
    score = 0
    active_count = dev.delegations.active.count
    score += (10 - [active_count, 10].min) * 5

    if dev.growth_areas.present? && topic.category.present?
      score += 30 if dev.growth_areas.downcase.include?(topic.category.downcase)
    end

    if dev.career_goals.present? && topic.summary.present?
      goal_words = dev.career_goals.downcase.split(/\W+/)
      topic_words = topic.summary.downcase.split(/\W+/)
      score += [(goal_words & topic_words).size * 10, 20].min
    end

    resolved_similar = dev.delegations.where(status: "done").where(issue_type: topic.category).count
    score += [resolved_similar * 10, 20].min

    score
  end

  def build_reason(dev, topic)
    parts = []
    active = dev.delegations.active.count
    parts << "#{active} active delegation#{'s' unless active == 1}"

    if dev.growth_areas.present? && topic.category.present? && dev.growth_areas.downcase.include?(topic.category.downcase)
      parts << "growth area matches (#{topic.category})"
    end

    resolved = dev.delegations.where(status: "done").where(issue_type: topic.category).count
    parts << "resolved #{resolved} similar issues" if resolved > 0

    parts.join(", ")
  end
end
