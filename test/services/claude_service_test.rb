require "test_helper"

class ClaudeServiceTest < ActiveSupport::TestCase
  test "analyze via api returns text from response" do
    mock_client = Object.new
    mock_client.define_singleton_method(:messages) do |**_|
      { "content" => [{ "text" => "analysis result" }] }
    end

    result = ClaudeService.new(client: mock_client).analyze("test prompt")
    assert_equal "analysis result", result
  end

  test "configured? returns false for api backend without key" do
    Setting.set("global", "ai_backend", "api")
    EncryptedSetting.where(scope: "credentials", key: "anthropic_api_key").delete_all
    assert_not ClaudeService.new.configured?
  end

  test "configured? returns true for api backend with key" do
    Setting.set("global", "ai_backend", "api")
    EncryptedSetting.set("credentials", "anthropic_api_key", "sk-ant-test")
    assert ClaudeService.new.configured?
  end

  test "backend defaults to cli" do
    Setting.where(scope: "global", key: "ai_backend").delete_all
    service = ClaudeService.new
    assert_equal "cli", service.send(:backend)
  end

  test "explicit client forces api backend" do
    mock_client = Object.new
    mock_client.define_singleton_method(:messages) { |**_| { "content" => [{ "text" => "ok" }] } }

    service = ClaudeService.new(client: mock_client)
    assert_equal "api", service.send(:backend)
  end
end
