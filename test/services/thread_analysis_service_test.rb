require "test_helper"

class ThreadAnalysisServiceTest < ActiveSupport::TestCase
  setup do
    @thread = slack_threads(:one)
    @embedding = Array.new(1536, 0.1)
    @thread.slack_messages.create!(message_ts: "10.1", content: "There's a login bug", user_name: "Alice", message_ts_at: 1.hour.ago)
    @thread.slack_messages.create!(message_ts: "10.2", content: "Also the API is slow", user_name: "Bob", message_ts_at: 30.minutes.ago)
    @thread.slack_topics.destroy_all
    @thread.update!(pending_reanalysis: true)
  end

  test "analyzes thread and extracts topics" do
    analysis_json = {
      title: "Login bug and API performance",
      summary: "Two issues discussed: login bug and API slowness.",
      category: "incident",
      keywords: ["login", "api", "performance"],
      topics: [
        { title: "Login bug", summary: "Users can't log in", category: "bug", urgency: "high", action: "create_ticket", related_message_indices: [0] },
        { title: "API slowness", summary: "API response time degraded", category: "bug", urgency: "medium", action: "delegate", related_message_indices: [1] }
      ]
    }.to_json

    mock_anthropic = Object.new
    mock_anthropic.define_singleton_method(:messages) { |**_| { "content" => [{ "text" => analysis_json }] } }

    mock_embedder = Object.new
    mock_embedder.define_singleton_method(:embed) { |text| Array.new(1536, 0.1) }

    service = ThreadAnalysisService.new(embedding_service: mock_embedder, anthropic_client: mock_anthropic)
    service.analyze(@thread)

    @thread.reload
    assert_equal "Login bug and API performance", @thread.title
    assert_not @thread.pending_reanalysis?
    assert_not_nil @thread.last_analyzed_at
    assert_equal 2, @thread.slack_topics.count

    login_topic = @thread.slack_topics.find_by(title: "Login bug")
    assert_equal "high", login_topic.urgency
    assert_equal "create_ticket", login_topic.action_recommendation
    assert_equal 1, login_topic.slack_messages.count
  end

  test "handles empty messages gracefully" do
    thread = slack_threads(:two)
    thread.slack_messages.destroy_all
    service = ThreadAnalysisService.new
    assert_nothing_raised { service.analyze(thread) }
  end
end
