require "test_helper"

class ActionQueueServiceTest < ActiveSupport::TestCase
  test "creates action item from actionable topic" do
    thread = create(:slack_thread)
    topic = create(:slack_topic, slack_thread: thread, action_recommendation: "create_ticket", status: "open")

    mock_drafter = Object.new
    mock_drafter.define_singleton_method(:draft) { |t| { title: "Issue title", body: "Issue body", suggested_repo: nil } }

    mock_suggester = Object.new
    mock_suggester.define_singleton_method(:suggest) { |t| nil }

    service = ActionQueueService.new(ticket_draft_service: mock_drafter, assignee_suggestion_service: mock_suggester)

    assert_difference("ActionItem.count") do
      service.process(topic)
    end

    item = ActionItem.last
    assert_equal "Issue title", item.draft_title
    assert_equal "pending", item.status
    assert_equal topic, item.slack_topic
  end

  test "skips non-actionable topics" do
    thread = create(:slack_thread)
    topic = create(:slack_topic, slack_thread: thread, action_recommendation: "acknowledge", status: "open")

    mock_drafter = Object.new
    mock_drafter.define_singleton_method(:draft) { |t| { title: "x", body: "x", suggested_repo: nil } }
    mock_suggester = Object.new
    mock_suggester.define_singleton_method(:suggest) { |t| nil }

    service = ActionQueueService.new(ticket_draft_service: mock_drafter, assignee_suggestion_service: mock_suggester)
    assert_no_difference("ActionItem.count") { service.process(topic) }
  end

  test "skips duplicate topics" do
    thread = create(:slack_thread)
    topic = create(:slack_topic, slack_thread: thread, action_recommendation: "delegate", status: "open")
    create(:action_item, slack_topic: topic, slack_thread: thread)

    mock_drafter = Object.new
    mock_drafter.define_singleton_method(:draft) { |t| { title: "x", body: "x", suggested_repo: nil } }
    mock_suggester = Object.new
    mock_suggester.define_singleton_method(:suggest) { |t| nil }

    service = ActionQueueService.new(ticket_draft_service: mock_drafter, assignee_suggestion_service: mock_suggester)
    assert_no_difference("ActionItem.count") { service.process(topic) }
  end

  test "skips non-open topics" do
    thread = create(:slack_thread)
    topic = create(:slack_topic, slack_thread: thread, action_recommendation: "delegate", status: "actioned")

    mock_drafter = Object.new
    mock_drafter.define_singleton_method(:draft) { |t| { title: "x", body: "x", suggested_repo: nil } }
    mock_suggester = Object.new
    mock_suggester.define_singleton_method(:suggest) { |t| nil }

    service = ActionQueueService.new(ticket_draft_service: mock_drafter, assignee_suggestion_service: mock_suggester)
    assert_no_difference("ActionItem.count") { service.process(topic) }
  end
end
