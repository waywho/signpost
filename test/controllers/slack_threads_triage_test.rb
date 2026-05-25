require "test_helper"

class SlackThreadsTriageTest < ActionDispatch::IntegrationTest
  setup do
    @thread = slack_threads(:one)
    @thread.update!(status: "new")
  end

  test "dismiss marks thread archived" do
    post dismiss_slack_thread_path(@thread)
    assert_redirected_to slack_threads_path
    assert_equal "archived", @thread.reload.status
  end

  test "delegate creates delegation and marks actioned" do
    assert_difference("Delegation.count") do
      post delegate_slack_thread_path(@thread)
    end
    assert_equal "actioned", @thread.reload.status
    delegation = Delegation.last
    assert_equal @thread.title, delegation.summary
    assert_redirected_to edit_delegation_path(delegation)
  end

  test "delegate_topic creates delegation from specific topic" do
    embedding = Array.new(1536, 0.1)
    topic = @thread.slack_topics.create!(title: "Specific bug", summary: "A specific bug", status: "open", urgency: "high", embedding: embedding)

    assert_difference("Delegation.count") do
      post delegate_slack_thread_slack_topic_path(@thread, topic)
    end

    delegation = Delegation.last
    assert_equal "Specific bug", delegation.summary
    assert_equal "High", delegation.urgency
    assert_equal "actioned", topic.reload.status
    assert_redirected_to edit_delegation_path(delegation)
  end

  test "acknowledge marks thread triaged" do
    # Acknowledge will fail to post to Slack (no real token) but should still mark triaged
    post acknowledge_slack_thread_path(@thread)
    assert_redirected_to slack_threads_path
    assert_equal "triaged", @thread.reload.status
  end
end
