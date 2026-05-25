class SlackService
  def initialize(client: nil)
    @explicit_client = client
  end

  def configured?
    EncryptedSetting.get("credentials", "slack_bot_token").present?
  end

  def add_reaction(channel:, timestamp:, emoji:)
    client.reactions_add(channel: channel, timestamp: timestamp, name: emoji)
  end

  private

  def client
    @explicit_client || Slack::Web::Client.new(
      token: EncryptedSetting.get("credentials", "slack_bot_token")
    )
  end
end
