module PrReviewsHelper
  RECOMMENDATION_COLORS = {
    "approve" => "var(--color-positive)",
    "request_changes" => "var(--color-negative)",
    "needs_discussion" => "#f97316"
  }.freeze

  RISK_COLORS = {
    "low" => "var(--color-positive)",
    "medium" => "#f97316",
    "high" => "var(--color-negative)",
    "critical" => "var(--color-negative)"
  }.freeze

  def recommendation_color(rec)
    RECOMMENDATION_COLORS.fetch(rec.to_s, "var(--color-text-subtle)")
  end

  RECOMMENDATION_BADGE_VARIANTS = {
    "approve" => "badge--positive",
    "request_changes" => "badge--negative",
    "needs_discussion" => "badge--secondary"
  }.freeze

  def recommendation_badge_variant(rec)
    RECOMMENDATION_BADGE_VARIANTS.fetch(rec.to_s, "")
  end

  RISK_BADGE_VARIANTS = {
    "low" => "badge--positive",
    "medium" => "badge--secondary",
    "high" => "badge--negative",
    "critical" => "badge--negative"
  }.freeze

  def risk_badge_variant(level)
    RISK_BADGE_VARIANTS.fetch(level.to_s, "")
  end

  def risk_color(level)
    RISK_COLORS.fetch(level.to_s, "var(--color-text-subtle)")
  end
end
