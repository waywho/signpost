require "test_helper"

class SlackThreadsTriageTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread, status: "new_thread")
  end

  test "dismiss marks thread archived" do
    post slack_thread_dismissal_path(@thread)
    assert_redirected_to slack_threads_path
    assert_equal "archived", @thread.reload.status
  end

  test "delegate redirects to new delegation form with pre-filled params" do
    post slack_thread_delegation_path(@thread)
    assert_redirected_to new_delegation_path(delegation: {
      summary: @thread.title,
      slack_channel_id: @thread.slack_channel_id,
      slack_thread_ts: @thread.slack_thread_ts
    })
  end

  test "delegate_topic redirects to new delegation form with topic details" do
    embedding = Array.new(1536, 0.1)
    topic = @thread.slack_topics.create!(title: "Specific bug", summary: "A specific bug", status: "open", urgency: "high", category: "bug", embedding: embedding)

    post slack_thread_slack_topic_delegation_path(@thread, topic)
    assert_redirected_to new_delegation_path(delegation: {
      summary: "Specific bug",
      slack_channel_id: @thread.slack_channel_id,
      slack_thread_ts: @thread.slack_thread_ts,
      urgency: "high",
      issue_type: "bug"
    })
  end

  test "acknowledge marks thread triaged" do
    # Acknowledge will fail to post to Slack (no real token) but should still mark triaged
    post slack_thread_acknowledgement_path(@thread)
    assert_redirected_to slack_threads_path
    assert_equal "triaged", @thread.reload.status
  end
end
