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

  def risk_color(level)
    RISK_COLORS.fetch(level.to_s, "var(--color-text-subtle)")
  end
end
