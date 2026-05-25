require "test_helper"

class SlackSearchServiceTest < ActiveSupport::TestCase
  test "search returns empty for no data" do
    mock_embedder = Object.new
    mock_embedder.define_singleton_method(:embed) { |text| Array.new(1536, 0.1) }

    service = SlackSearchService.new(embedding_service: mock_embedder)
    results = service.search(query: "test", threshold: 0.5)

    assert_kind_of Array, results
  end

  test "search finds messages by similarity" do
    thread = create(:slack_thread)
    embedding = Array.new(1536, 0.1)
    thread.slack_messages.create!(message_ts: "s.1", content: "database migration", embedding: embedding, message_ts_at: 1.hour.ago)

    mock_embedder = Object.new
    mock_embedder.define_singleton_method(:embed) { |text| Array.new(1536, 0.1) }

    service = SlackSearchService.new(embedding_service: mock_embedder)
    results = service.search(query: "database", threshold: 0.5, levels: ["message"])

    assert results.any?
    assert_equal "message", results.first[:type]
  end
end
