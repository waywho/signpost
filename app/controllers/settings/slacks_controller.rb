class Settings::SlacksController < ApplicationController
  include SlackPanelData

  CAPTURE_KEYS = %w[slack_capture_mode slack_brain_emoji poll_interval_minutes].freeze
  INTEGER_KEYS = %w[poll_interval_minutes].freeze

  def show
    load_slack_panel_data
  end

  def update
    case params[:form]
    when "tokens"
      SLACK_TOKENS.each do |key|
        next if params[key].blank?
        EncryptedSetting.set("credentials", key, params[key])
      end
    when "capture"
      CAPTURE_KEYS.each do |key|
        next if params[key].blank?
        value = INTEGER_KEYS.include?(key) ? params[key].to_i : params[key]
        Setting.set("global", key, value)
      end
    end
    load_slack_panel_data
    render :show
  end
end
