class SearchController < ApplicationController
  def create
    if params[:query].blank?
      render json: { error: "query is required" }, status: :unprocessable_entity
      return
    end

    results = SlackSearchService.new.search(
      query: params[:query],
      threshold: params[:threshold]&.to_f,
      limit: params[:limit]&.to_i || 20,
      levels: params[:levels],
      filters: search_filters
    )

    render json: { query: params[:query], results: results, count: results.size }
  end

  private

  def search_filters
    return {} unless params[:filters].present?
    params[:filters].permit(:category, :urgency, :date_from, :date_to, channel_ids: []).to_h.symbolize_keys
  end
end
