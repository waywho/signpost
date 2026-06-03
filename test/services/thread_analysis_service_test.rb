require "test_helper"

class ThreadAnalysisServiceTest < ActiveSupport::TestCase
  setup do
    @thread = create(:slack_thread)
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
      keywords: [ "login", "api", "performance" ],
      topics: [
        { title: "Login bug", summary: "Users can't log in", category: "bug", urgency: "high", action: "create_ticket", related_message_indices: [ 0 ] },
        { title: "API slowness", summary: "API response time degraded", category: "bug", urgency: "medium", action: "delegate", related_message_indices: [ 1 ] }
      ]
    }.to_json

    mock_claude = Object.new
    mock_claude.define_singleton_method(:analyze) { |prompt, **_| analysis_json }

    mock_embedder = Object.new
    mock_embedder.define_singleton_method(:embed) { |text| Array.new(1536, 0.1) }

    service = ThreadAnalysisService.new(embedding_service: mock_embedder, claude_service: mock_claude)
    noop_queue = ->(topic) { nil }
    original_new = ActionQueueService.method(:new)
    ActionQueueService.define_singleton_method(:new) do |**_args|
      obj = original_new.call(
        ticket_draft_service: Object.new.tap { |d| d.define_singleton_method(:draft) { |_| { title: "x", body: "x", suggested_repo: nil } } },
        assignee_suggestion_service: Object.new.tap { |s| s.define_singleton_method(:suggest) { |_| nil } }
      )
      obj
    end
    service.analyze(@thread)
  ensure
    ActionQueueService.define_singleton_method(:new, original_new) if original_new

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
    thread = create(:slack_thread)
    thread.slack_messages.destroy_all
    service = ThreadAnalysisService.new
    assert_nothing_raised { service.analyze(thread) }
  end
end
