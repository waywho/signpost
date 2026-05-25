class SettingsController < ApplicationController
  def show
    @watched_channels = WatchedChannel.order(:channel_name)
    @noise_filters = NoiseFilter.order(:category)
  end

  def update
    case params[:section]
    when "ai_backend"
      Setting.set("global", "ai_backend", params[:ai_backend]) if params[:ai_backend].in?(ClaudeService::BACKENDS)
      EncryptedSetting.set("credentials", "anthropic_api_key", params[:anthropic_api_key]) if params[:anthropic_api_key].present?
    when "api_keys"
      update_api_keys
    when "github"
      update_github
    when "slack"
      update_slack
    when "search"
      update_search
    when "compression"
      update_compression
    when "watched_channel_add"
      add_watched_channel
    when "watched_channel_remove"
      remove_watched_channel
    when "noise_filter_add"
      add_noise_filter
    when "noise_filter_remove"
      remove_noise_filter
    when "calendar"
      update_calendar
    end

    redirect_to settings_path, notice: "Settings saved."
  end

  private

  def update_api_keys
    %w[openai_api_key anthropic_api_key github_pat slack_bot_token slack_user_token slack_app_token].each do |key|
      value = params[key]
      EncryptedSetting.set("credentials", key, value) if value.present?
    end
  end

  def update_github
    Setting.set("global", "github_username", params[:github_username]) if params[:github_username].present?
    if params[:github_repos].present?
      repos = params[:github_repos].split(",").map(&:strip).reject(&:blank?)
      Setting.set("global", "github_repos", repos)
    end
  end

  def update_slack
    Setting.set("global", "slack_capture_mode", params[:slack_capture_mode]) if params[:slack_capture_mode].present?
    Setting.set("global", "slack_brain_emoji", params[:slack_brain_emoji]) if params[:slack_brain_emoji].present?
    Setting.set("global", "poll_interval_minutes", params[:poll_interval_minutes].to_i) if params[:poll_interval_minutes].present?
  end

  def update_search
    Setting.set("global", "search_default_threshold", params[:search_default_threshold].to_f) if params[:search_default_threshold].present?
  end

  def update_compression
    Setting.set("global", "compression_after_months", params[:compression_after_months].to_i) if params[:compression_after_months].present?
    Setting.set("global", "reanalysis_message_threshold", params[:reanalysis_message_threshold].to_i) if params[:reanalysis_message_threshold].present?
    Setting.set("global", "reanalysis_quiet_minutes", params[:reanalysis_quiet_minutes].to_i) if params[:reanalysis_quiet_minutes].present?
  end

  def add_watched_channel
    WatchedChannel.create!(
      channel_id: params[:channel_id],
      channel_name: params[:channel_name],
      capture_mode: params[:capture_mode]
    )
  rescue ActiveRecord::RecordInvalid => e
    redirect_to settings_path, alert: e.message and return
  end

  def remove_watched_channel
    WatchedChannel.find_by(channel_id: params[:channel_id])&.destroy
  end

  def add_noise_filter
    NoiseFilter.create!(category: params[:filter_category], description: params[:filter_description])
  rescue ActiveRecord::RecordInvalid => e
    redirect_to settings_path, alert: e.message and return
  end

  def remove_noise_filter
    NoiseFilter.find(params[:filter_id])&.destroy
  end

  def update_calendar
    value = params[:google_ical_url]
    EncryptedSetting.set("credentials", "google_ical_url", value) if value.present?
  end
end
