require "test_helper"

class ThreadCompressionJobTest < ActiveSupport::TestCase
  setup do
    Setting.set("global", "compression_after_months", 0)
    # Clear fixture data so it doesn't interfere with test isolation
    SlackTopicMessage.delete_all
    SlackTopic.delete_all
    SlackMessage.delete_all
  end

  test "compresses old thread without open topics" do
    thread = slack_threads(:one)
    thread.update!(captured_at: 1.day.ago)
    embedding = Array.new(1536, 0.1)
    thread.slack_messages.create!(message_ts: "c.1", content: "old message", embedding: embedding, message_ts_at: 1.day.ago)

    ThreadCompressionJob.perform_now

    thread.reload
    assert thread.compressed?
    assert_equal 0, thread.slack_messages.count
  end

  test "skips thread with open topics" do
    thread = slack_threads(:one)
    thread.update!(captured_at: 1.day.ago)
    embedding = Array.new(1536, 0.1)
    thread.slack_messages.create!(message_ts: "c.2", content: "msg", embedding: embedding, message_ts_at: 1.day.ago)
    thread.slack_topics.create!(title: "open issue", summary: "desc", status: "open", embedding: embedding)

    ThreadCompressionJob.perform_now

    thread.reload
    assert_not thread.compressed?
    assert_equal 1, thread.slack_messages.count
  end

  test "preserves thread summary and topics after compression" do
    thread = slack_threads(:one)
    thread.update!(captured_at: 1.day.ago, summary: "important discussion", title: "test thread")
    embedding = Array.new(1536, 0.1)
    thread.slack_messages.create!(message_ts: "c.3", content: "msg", embedding: embedding, message_ts_at: 1.day.ago)
    thread.slack_topics.create!(title: "resolved", summary: "was fixed", status: "actioned", embedding: embedding)

    ThreadCompressionJob.perform_now

    thread.reload
    assert thread.compressed?
    assert_equal "important discussion", thread.summary
    assert_equal 1, thread.slack_topics.count
    assert_equal 0, thread.slack_messages.count
  end
end
