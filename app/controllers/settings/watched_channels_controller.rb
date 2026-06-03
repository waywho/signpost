class Settings::WatchedChannelsController < ApplicationController
  include SlackPanelData

  def create
    channel_id, channel_name = params[:channel_select].to_s.split("|", 2)
    WatchedChannel.create!(channel_id: channel_id, channel_name: channel_name, capture_mode: params[:capture_mode])
    load_slack_panel_data
    render template: "settings/slacks/show"
  rescue ActiveRecord::RecordInvalid
    load_slack_panel_data
    render template: "settings/slacks/show"
  end

  def destroy
    WatchedChannel.find_by(channel_id: params[:id])&.destroy
    load_slack_panel_data
    render template: "settings/slacks/show"
  end
end
