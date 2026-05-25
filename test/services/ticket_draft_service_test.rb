require "test_helper"

class TicketDraftServiceTest < ActiveSupport::TestCase
  test "draft returns structured issue" do
    thread = create(:slack_thread)
    topic = create(:slack_topic, slack_thread: thread)
    create(:slack_message, slack_thread: thread, content: "Login is broken")

    draft_json = { title: "Fix login bug", body: "## Context\nLogin broken", suggested_repo: "org/app" }.to_json
    mock_claude = Object.new
    mock_claude.define_singleton_method(:analyze) { |prompt, **_| draft_json }

    result = TicketDraftService.new(claude_service: mock_claude).draft(topic)
    assert_equal "Fix login bug", result[:title]
    assert_equal "org/app", result[:suggested_repo]
  end

  test "draft falls back on parse error" do
    thread = create(:slack_thread)
    topic = create(:slack_topic, slack_thread: thread, title: "My topic")

    mock_claude = Object.new
    mock_claude.define_singleton_method(:analyze) { |prompt, **_| "not json" }

    result = TicketDraftService.new(claude_service: mock_claude).draft(topic)
    assert_equal "My topic", result[:title]
  end
end
