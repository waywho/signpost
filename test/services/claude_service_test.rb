require "test_helper"

class ClaudeServiceTest < ActiveSupport::TestCase
  test "analyze returns text from response" do
    mock_client = Object.new
    mock_client.define_singleton_method(:messages) do |**_|
      { "content" => [{ "text" => "analysis result" }] }
    end

    result = ClaudeService.new(client: mock_client).analyze("test prompt")
    assert_equal "analysis result", result
  end

  test "configured? checks encrypted setting" do
    assert_not ClaudeService.new.configured?
  end
end
