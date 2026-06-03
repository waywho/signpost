module BadgesHelper
  BADGE_LABELS = {
    urgency: "Urgency",
    status: "Status",
    recommendation: "Recommended action",
    severity: "Severity",
    risk_level: "Risk level",
    analysis_status: "Analysis status",
    category: "Category",
    search_type: "Match type",
    channel: "Source channel",
    due: "Due",
    note_type: "Note type"
  }.freeze

  def badge_tooltip(scope)
    BADGE_LABELS[scope.to_sym]
  end
end
