require "test_helper"

class SlackTopicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread)
    @topic = create(:slack_topic, slack_thread: @thread, status: "open", urgency: "high")
    @item = create(:action_item, slack_topic: @topic, slack_thread: @thread,
                   draft_title: "Fix", draft_body: "Details")
  end

  test "update to dismissed dismisses topic and action items" do
    patch slack_thread_slack_topic_path(@thread, @topic), params: { status: "dismissed" }
    assert_redirected_to slack_thread_path(@thread)
    assert_equal "dismissed", @topic.reload.status
    assert_equal "dismissed", @item.reload.status
  end

  test "update to actioned resolves topic and action items" do
    patch slack_thread_slack_topic_path(@thread, @topic), params: { status: "actioned" }
    assert_redirected_to slack_thread_path(@thread)
    assert_equal "actioned", @topic.reload.status
    assert_equal "actioned", @item.reload.status
  end

  test "does not affect already actioned action items" do
    @item.update!(status: "resolved")
    patch slack_thread_slack_topic_path(@thread, @topic), params: { status: "dismissed" }
    assert_equal "resolved", @item.reload.status
  end
end
