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

  test "acknowledge marks thread triaged" do
    # Acknowledge will fail to post to Slack (no real token) but should still mark triaged
    post slack_thread_acknowledgement_path(@thread)
    assert_redirected_to slack_threads_path
    assert_equal "triaged", @thread.reload.status
  end
end
