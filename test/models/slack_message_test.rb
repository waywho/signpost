require "test_helper"

class SlackMessageTest < ActiveSupport::TestCase
  setup do
    @thread = create(:slack_thread)
  end

  test "valid with required fields" do
    msg = SlackMessage.new(slack_thread: @thread, message_ts: "9.1", content: "hello")
    assert msg.valid?
  end

  test "invalid without content" do
    msg = SlackMessage.new(slack_thread: @thread, message_ts: "9.1")
    assert_not msg.valid?
  end

  test "enforces uniqueness on thread + message_ts" do
    SlackMessage.create!(slack_thread: @thread, message_ts: "9.1", content: "first")
    dup = SlackMessage.new(slack_thread: @thread, message_ts: "9.1", content: "second")
    assert_not dup.valid?
  end

  test "chronological orders by message_ts_at" do
    early = SlackMessage.create!(slack_thread: @thread, message_ts: "9.1", content: "a", message_ts_at: 2.hours.ago)
    late = SlackMessage.create!(slack_thread: @thread, message_ts: "9.2", content: "b", message_ts_at: 1.hour.ago)
    msgs = SlackMessage.where(id: [ early.id, late.id ]).chronological
    assert_equal "a", msgs.first.content
    assert_equal "b", msgs.last.content
  end
end
