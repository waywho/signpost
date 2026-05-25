require "test_helper"

class SlackServiceTest < ActiveSupport::TestCase
  test "add_reaction calls Slack API" do
    mock_client = Object.new
    called_with = nil
    mock_client.define_singleton_method(:reactions_add) do |**args|
      called_with = args
    end

    service = SlackService.new(user_client: mock_client)
    service.add_reaction(channel: "C123", timestamp: "1.1", emoji: "brain")

    assert_equal({ channel: "C123", timestamp: "1.1", name: "brain" }, called_with)
  end

  test "configured? returns true when token exists" do
    EncryptedSetting.where(scope: "credentials", key: "slack_bot_token").delete_all
    EncryptedSetting.set("credentials", "slack_bot_token", "xoxb-test")
    service = SlackService.new
    assert service.configured?
  end

  test "configured? returns false when token missing" do
    EncryptedSetting.where(scope: "credentials", key: "slack_bot_token").delete_all
    service = SlackService.new
    assert_not service.configured?
  end
end
