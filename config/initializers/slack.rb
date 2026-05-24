Slack.configure do |config|
  config.token = -> { EncryptedSetting.get("credentials", "slack_bot_token") }
end
