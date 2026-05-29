require "test_helper"

class SlackTopicTest < ActiveSupport::TestCase
  setup do
    @thread = create(:slack_thread)
  end

  test "valid with required fields" do
    topic = SlackTopic.new(slack_thread: @thread, title: "Bug", summary: "A bug was found", status: "open")
    assert topic.valid?
  end

  test "invalid without title" do
    topic = SlackTopic.new(slack_thread: @thread, summary: "desc", status: "open")
    assert_not topic.valid?
  end

  test "rejects invalid urgency" do
    assert_raises(ArgumentError) { SlackTopic.new(slack_thread: @thread, title: "t", summary: "s", status: "open", urgency: "extreme") }
  end

  test "open scope" do
    existing_open = SlackTopic.open.count
    SlackTopic.create!(slack_thread: @thread, title: "a", summary: "s", status: "open")
    SlackTopic.create!(slack_thread: @thread, title: "b", summary: "s", status: "dismissed")
    assert_equal existing_open + 1, SlackTopic.open.count
  end
end
