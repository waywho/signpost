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
