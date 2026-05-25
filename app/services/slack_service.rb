class SlackService
  def initialize(bot_client: nil, user_client: nil)
    @explicit_bot_client = bot_client
    @explicit_user_client = user_client
  end

  def configured?
    EncryptedSetting.get("credentials", "slack_bot_token").present?
  end

  def add_reaction(channel:, timestamp:, emoji:)
    user_client.reactions_add(channel: channel, timestamp: timestamp, name: emoji)
  end

  def list_channels
    channels = bot_client.conversations_list(types: "public_channel,private_channel", exclude_archived: true, limit: 1000)
    channels.channels.map do |ch|
      { id: ch.id, name: ch.name, is_member: ch.is_member }
    end.select { |ch| ch[:is_member] }.sort_by { |ch| ch[:name] }
  rescue => e
    Rails.logger.error("SlackService list_channels error: #{e.message}")
    []
  end

  private

  # Bot token — for reading channels, events
  def bot_client
    @explicit_bot_client || Slack::Web::Client.new(
      token: EncryptedSetting.get("credentials", "slack_bot_token")
    )
  end

  # User token — for reacting/replying as the user (not the bot)
  def user_client
    @explicit_user_client || Slack::Web::Client.new(
      token: EncryptedSetting.get("credentials", "slack_user_token") ||
             EncryptedSetting.get("credentials", "slack_bot_token")
    )
  end
end
