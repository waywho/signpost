require "test_helper"

class SlackThreads::DismissalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread)
  end

  test "create dismisses thread" do
    post slack_thread_dismissal_path(@thread)
    assert_redirected_to slack_threads_path
    assert_equal "archived", @thread.reload.status
  end

  test "create dismisses open topics and their pending action items" do
    topic = create(:slack_topic, slack_thread: @thread, status: "open", urgency: "high")
    item = create(:action_item, slack_topic: topic, slack_thread: @thread,
                  draft_title: "Fix", draft_body: "Details")

    post slack_thread_dismissal_path(@thread)
    assert_equal "dismissed", topic.reload.status
    assert_equal "dismissed", item.reload.status
  end
end
