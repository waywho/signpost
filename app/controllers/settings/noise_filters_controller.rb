class Settings::NoiseFiltersController < ApplicationController
  include SlackPanelData

  def create
    NoiseFilter.create!(category: params[:filter_category], description: params[:filter_description])
    load_slack_panel_data
    render template: "settings/slacks/show"
  rescue ActiveRecord::RecordInvalid
    load_slack_panel_data
    render template: "settings/slacks/show"
  end

  def destroy
    NoiseFilter.find_by(id: params[:id])&.destroy
    load_slack_panel_data
    render template: "settings/slacks/show"
  end
end
