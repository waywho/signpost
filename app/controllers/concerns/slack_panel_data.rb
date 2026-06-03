module SlackPanelData
  extend ActiveSupport::Concern

  SLACK_TOKENS = %w[slack_bot_token slack_user_token slack_app_token].freeze

  private

  def load_slack_panel_data
    @watched_channels = WatchedChannel.order(:channel_name)
    @noise_filters = NoiseFilter.order(:category)

    slack_service = SlackService.new
    @slack_configured = slack_service.configured?
    available_channels = @slack_configured ? Rails.cache.fetch("slack/channels", expires_in: 5.minutes) { slack_service.list_channels } : []
    watched_ids = @watched_channels.map(&:channel_id)
    @unwatched_channels = available_channels.reject { |ch| watched_ids.include?(ch[:id]) }

    @slack_capture_mode = Setting.get("global", "slack_capture_mode", default: "both")
    @slack_brain_emoji = Setting.get("global", "slack_brain_emoji", default: "brain")
    @poll_interval_minutes = Setting.get("global", "poll_interval_minutes", default: 15)
    @slack_user_id = Setting.get("global", "slack_user_id")
    @slack_token_present = SLACK_TOKENS.each_with_object({}) { |k, h| h[k] = EncryptedSetting.get("credentials", k).present? }
  end
end
