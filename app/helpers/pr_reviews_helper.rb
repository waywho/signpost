module PrReviewsHelper
  RECOMMENDATION_COLORS = {
    "APPROVE" => "var(--color-positive)",
    "REQUEST_CHANGES" => "var(--color-negative)",
    "NEEDS_DISCUSSION" => "#f97316"
  }.freeze

  RISK_COLORS = {
    "LOW" => "var(--color-positive)",
    "MEDIUM" => "#f97316",
    "HIGH" => "var(--color-negative)",
    "CRITICAL" => "var(--color-negative)"
  }.freeze

  def recommendation_color(rec)
    RECOMMENDATION_COLORS.fetch(rec.to_s, "var(--color-text-subtle)")
  end

  RECOMMENDATION_BADGE_VARIANTS = {
    "APPROVE" => "badge--positive",
    "REQUEST_CHANGES" => "badge--negative",
    "NEEDS_DISCUSSION" => "badge--secondary"
  }.freeze

  def recommendation_badge_variant(rec)
    RECOMMENDATION_BADGE_VARIANTS.fetch(rec.to_s, "")
  end

  RISK_BADGE_VARIANTS = {
    "LOW" => "badge--positive",
    "MEDIUM" => "badge--secondary",
    "HIGH" => "badge--negative",
    "CRITICAL" => "badge--negative"
  }.freeze

  def risk_badge_variant(level)
    RISK_BADGE_VARIANTS.fetch(level.to_s, "")
  end

  def risk_color(level)
    RISK_COLORS.fetch(level.to_s, "var(--color-text-subtle)")
  end
end
