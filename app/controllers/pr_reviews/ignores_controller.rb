class PrReviews::IgnoresController < ApplicationController
  def create
    urls = Array(params[:urls].presence || params[:url])
    ignored = Setting.get("global", "ignored_prs", default: []) || []
    urls.each { |url| ignored << url unless ignored.include?(url) }
    Setting.set("global", "ignored_prs", ignored)
    count = urls.size
    redirect_back fallback_location: pr_reviews_path, notice: "#{count} PR#{'s' if count > 1} ignored."
  end
end
