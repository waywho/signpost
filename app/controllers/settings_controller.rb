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
    # Preload all settings to avoid N+1 queries in view
    preload_settings!

    @watched_channels = WatchedChannel.order(:channel_name)
    @noise_filters = NoiseFilter.order(:category)

    # Slack channels (cached 5 min to avoid slow API pagination on every load)
    slack_service = SlackService.new
    @slack_configured = slack_service.configured?
    available_channels = @slack_configured ? Rails.cache.fetch("slack/channels", expires_in: 5.minutes) { slack_service.list_channels } : []
    watched_ids = @watched_channels.map(&:channel_id)
    @unwatched_channels = available_channels.reject { |ch| watched_ids.include?(ch[:id]) }

    # GitHub repos
    github_service = GitHubService.new
    @github_configured = github_service.configured?
    @available_repos = @github_configured ? (github_service.list_repos rescue []) : []
    @selected_repos = Setting.get("global", "github_repos", default: []) || []
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

    anchor = section_anchor(params[:section])
    redirect_to settings_path(anchor: anchor), notice: "Settings saved."
  rescue ActiveRecord::RecordInvalid => e
    anchor = section_anchor(params[:section])
    redirect_to settings_path(anchor: anchor), alert: e.message
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

  def section_anchor(section)
    case section
    when "slack_tokens", "watched_channel_add", "watched_channel_remove", "noise_filter_add", "noise_filter_remove"
      "slack"
    else
      section
    end
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

  def preload_settings!
    # Batch-load all settings and encrypted settings into Current.setting_cache
    Setting.where(scope: "global").each do |s|
      Current.setting_cache["#{s.scope}/#{s.key}"] = s.value
    end
    EncryptedSetting.where(scope: "credentials").each do |es|
      Current.setting_cache["encrypted/#{es.scope}/#{es.key}"] = es.value
    end
  end

end
