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
end
