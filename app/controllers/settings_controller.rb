class SettingsController < ApplicationController
  SETTINGS = {
    "github"      => %w[github_username],
    "slack"       => %w[slack_capture_mode slack_brain_emoji poll_interval_minutes],
    "search"      => %w[search_default_threshold],
    "compression" => %w[compression_after_months reanalysis_message_threshold reanalysis_quiet_minutes]
  }.freeze

  INTEGER_SETTINGS = %w[poll_interval_minutes compression_after_months reanalysis_message_threshold reanalysis_quiet_minutes].freeze
  FLOAT_SETTINGS = %w[search_default_threshold].freeze

  API_KEYS = %w[openai_api_key].freeze
  SLACK_TOKENS = %w[slack_bot_token slack_user_token slack_app_token].freeze

  def show
    @watched_channels = WatchedChannel.order(:channel_name)
    @noise_filters = NoiseFilter.order(:category)
  end

  def update
    case params[:section]
    when "ai_backend"
      Setting.set("global", "ai_backend", params[:ai_backend]) if params[:ai_backend].in?(ClaudeService::BACKENDS)
      save_encrypted(:anthropic_api_key)
    when "api_keys"
      API_KEYS.each { |key| save_encrypted(key) }
    when "slack_tokens"
      SLACK_TOKENS.each { |key| save_encrypted(key) }
    when "github", "slack", "search", "compression"
      save_settings(params[:section])
    when "watched_channel_add"
      channel_id, channel_name = params[:channel_select].to_s.split("|", 2)
      WatchedChannel.create!(channel_id: channel_id, channel_name: channel_name, capture_mode: params[:capture_mode])
    when "watched_channel_remove"
      WatchedChannel.find_by(channel_id: params[:channel_id])&.destroy
    when "noise_filter_add"
      NoiseFilter.create!(category: params[:filter_category], description: params[:filter_description])
    when "noise_filter_remove"
      NoiseFilter.find(params[:filter_id])&.destroy
    when "calendar"
      save_encrypted(:google_ical_url)
    end

    redirect_to settings_path, notice: "Settings saved."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to settings_path, alert: e.message
  end

  private

  def save_settings(section)
    SETTINGS.fetch(section, []).each do |key|
      next unless params[key].present?
      value = cast_value(key, params[key])
      Setting.set("global", key, value)
    end

    if section == "github"
      save_encrypted(:github_pat)
      save_github_repos
    end
  end

  def save_encrypted(key)
    value = params[key.to_s]
    EncryptedSetting.set("credentials", key.to_s, value) if value.present?
  end

  def save_github_repos
    repos = Array(params[:github_repos]).reject(&:blank?)
    Setting.set("global", "github_repos", repos)
  end

  def cast_value(key, value)
    if key.in?(INTEGER_SETTINGS)
      value.to_i
    elsif key.in?(FLOAT_SETTINGS)
      value.to_f
    else
      value
    end
  end
end
