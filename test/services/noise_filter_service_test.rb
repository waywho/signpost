require "test_helper"

class NoiseFilterServiceTest < ActiveSupport::TestCase
  setup do
    NoiseFilter.create!(category: "deploy_notification", description: "Deploy notifications", enabled: true)
  end

  test "returns true for noise" do
    mock_response = { "content" => [ { "text" => "NOISE" } ] }
    mock_client = Object.new
    mock_client.define_singleton_method(:messages) { |**| mock_response }

    assert NoiseFilterService.new(client: mock_client).noise?("Deploy v1.2.3 complete")
  end

  test "returns false for non-noise" do
    mock_response = { "content" => [ { "text" => "KEEP" } ] }
    mock_client = Object.new
    mock_client.define_singleton_method(:messages) { |**| mock_response }

    assert_not NoiseFilterService.new(client: mock_client).noise?("We need to discuss the API redesign")
  end

  test "returns false when no filters enabled" do
    NoiseFilter.update_all(enabled: false)
    assert_not NoiseFilterService.new.noise?("anything")
  end

  test "returns false on error" do
    mock_client = Object.new
    def mock_client.messages(**) = raise(StandardError, "API down")

    assert_not NoiseFilterService.new(client: mock_client).noise?("test")
  end
end
