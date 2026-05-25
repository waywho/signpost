module SlackThreadsHelper
  CATEGORY_ICONS = {
    "architecture" => "ph-graph",
    "stakeholder" => "ph-handshake",
    "team-decision" => "ph-users-three",
    "incident" => "ph-warning-circle",
    "other" => "ph-chat-dots"
  }.freeze

  def category_icon(category)
    CATEGORY_ICONS.fetch(category.to_s, "ph-chat-dots")
  end

  def urgency_color(urgency)
    case urgency
    when "critical" then "var(--color-negative)"
    when "high" then "#f97316"
    when "medium" then "var(--color-primary)"
    else "var(--color-text-subtle)"
    end
  end

  def urgency_badge_variant(urgency)
    case urgency&.downcase
    when "critical" then "badge--negative"
    when "high" then "badge--secondary"
    when "medium" then "badge--primary"
    else ""
    end
  end

  def status_color(status)
    case status
    when "new" then "var(--color-primary)"
    when "actioned" then "var(--color-positive)"
    else "var(--color-text-subtle)"
    end
  end

  def status_badge_variant(status)
    case status
    when "new" then "badge--primary"
    when "actioned" then "badge--positive"
    when "archived" then ""
    else ""
    end
  end

  def highest_urgency(thread)
    thread.slack_topics.map(&:urgency).compact.min_by do |u|
      %w[critical high medium low].index(u) || 99
    end
  end
end
