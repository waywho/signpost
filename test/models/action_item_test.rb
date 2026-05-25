require "test_helper"

class ActionItemTest < ActiveSupport::TestCase
  test "valid with required fields" do
    thread = create(:slack_thread)
    topic = create(:slack_topic, slack_thread: thread)
    item = build(:action_item, slack_topic: topic, slack_thread: thread)
    assert item.valid?
  end

  test "enforces uniqueness on slack_topic" do
    thread = create(:slack_thread)
    topic = create(:slack_topic, slack_thread: thread)
    create(:action_item, slack_topic: topic, slack_thread: thread)
    dup = build(:action_item, slack_topic: topic, slack_thread: thread)
    assert_not dup.valid?
  end

  test "pending scope" do
    thread = create(:slack_thread)
    topic1 = create(:slack_topic, slack_thread: thread)
    topic2 = create(:slack_topic, slack_thread: thread, title: "Other")
    create(:action_item, slack_topic: topic1, slack_thread: thread, status: "pending")
    create(:action_item, slack_topic: topic2, slack_thread: thread, status: "approved")
    assert_equal 1, ActionItem.pending.count
  end

  test "by_priority orders lower first" do
    thread = create(:slack_thread)
    topic1 = create(:slack_topic, slack_thread: thread)
    topic2 = create(:slack_topic, slack_thread: thread, title: "Other")
    create(:action_item, slack_topic: topic2, slack_thread: thread, priority: 20)
    high = create(:action_item, slack_topic: topic1, slack_thread: thread, priority: 5)
    assert_equal high, ActionItem.by_priority.first
  end
end
