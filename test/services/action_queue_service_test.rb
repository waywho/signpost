require "test_helper"

class MockDrafter
  def draft(topic)
    @last_topic = topic
    @response || { title: "Fix it", body: "Details", suggested_repo: "org/repo" }
  end

  def set_response(response) = @response = response
  attr_reader :last_topic
end

class MockSuggester
  def initialize(developer: nil, reason: nil)
    @developer = developer
    @reason = reason
  end

  def suggest(_topic)
    return nil unless @developer
    { developer: @developer, reason: @reason }
  end
end

class ActionQueueServiceTest < ActiveSupport::TestCase
  setup do
    @drafter = MockDrafter.new
    @suggester = MockSuggester.new
    @service = ActionQueueService.new(
      ticket_draft_service: @drafter,
      assignee_suggestion_service: @suggester
    )
  end

  test "create_ticket: drafts ticket, suggests dev" do
    topic = create(:slack_topic, action_recommendation: "create_ticket", status: "open")
    dev = create(:developer)
    @suggester = MockSuggester.new(developer: dev, reason: "low workload")
    service = ActionQueueService.new(ticket_draft_service: @drafter, assignee_suggestion_service: @suggester)

    service.process(topic)

    item = ActionItem.find_by(slack_topic: topic)
    assert_equal "create_ticket", item.action_type
    assert_equal "pending", item.status
    assert_equal "Fix it", item.draft_title
    assert_equal dev, item.suggested_developer
  end

  test "delegate: suggests dev but no ticket draft" do
    topic = create(:slack_topic, action_recommendation: "delegate", status: "open")
    dev = create(:developer)
    @suggester = MockSuggester.new(developer: dev, reason: "growth match")
    service = ActionQueueService.new(ticket_draft_service: @drafter, assignee_suggestion_service: @suggester)

    service.process(topic)

    item = ActionItem.find_by(slack_topic: topic)
    assert_equal "delegate", item.action_type
    assert_nil item.draft_title
    assert_equal dev, item.suggested_developer
  end

  test "acknowledge: creates item with no AI pre-work" do
    topic = create(:slack_topic, action_recommendation: "acknowledge", status: "open")
    @service.process(topic)

    item = ActionItem.find_by(slack_topic: topic)
    assert_equal "acknowledge", item.action_type
    assert_equal "pending", item.status
    assert_nil item.draft_title
  end

  test "discuss: creates item with no AI pre-work" do
    topic = create(:slack_topic, action_recommendation: "discuss", status: "open")
    @service.process(topic)

    item = ActionItem.find_by(slack_topic: topic)
    assert_equal "discuss", item.action_type
    assert_equal "pending", item.status
  end

  test "ignore: creates item with ignored status" do
    topic = create(:slack_topic, action_recommendation: "ignore", status: "open")
    @service.process(topic)

    item = ActionItem.find_by(slack_topic: topic)
    assert_equal "ignore", item.action_type
    assert_equal "ignored", item.status
  end

  test "skips if action item already exists" do
    topic = create(:slack_topic, action_recommendation: "acknowledge", status: "open")
    create(:action_item, slack_topic: topic, slack_thread: topic.slack_thread, action_type: "acknowledge")

    assert_no_difference "ActionItem.count" do
      @service.process(topic)
    end
  end

  test "skips if topic not open" do
    topic = create(:slack_topic, action_recommendation: "delegate", status: "actioned")

    assert_no_difference "ActionItem.count" do
      @service.process(topic)
    end
  end

  test "draft_ticket generates draft on demand" do
    topic = create(:slack_topic, action_recommendation: "delegate", status: "open")
    item = create(:action_item, slack_topic: topic, slack_thread: topic.slack_thread,
                  action_type: "delegate", draft_title: nil, draft_body: nil)

    @drafter.set_response({ title: "New title", body: "New body", suggested_repo: "org/repo" })
    @service.draft_ticket(item)

    item.reload
    assert_equal "New title", item.draft_title
    assert_equal "New body", item.draft_body
  end

  test "draft_ticket skips if draft already exists" do
    topic = create(:slack_topic, action_recommendation: "delegate", status: "open")
    item = create(:action_item, slack_topic: topic, slack_thread: topic.slack_thread,
                  action_type: "delegate", draft_title: "Existing")

    @service.draft_ticket(item)
    item.reload
    assert_equal "Existing", item.draft_title
  end
end
