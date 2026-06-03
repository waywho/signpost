class Settings::SearchesController < ApplicationController
  def show
    load_data
  end

  def update
    if params[:search_default_threshold].present?
      Setting.set("global", "search_default_threshold", params[:search_default_threshold].to_f)
    end
    load_data
    render :show
  end

  private

  def load_data
    @search_default_threshold = Setting.get("global", "search_default_threshold", default: 0.75)
  end
end
