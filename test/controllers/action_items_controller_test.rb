require "test_helper"

class ActionItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread)
    @topic = create(:slack_topic, slack_thread: @thread, status: "open", urgency: "high")
    @item = create(:action_item, slack_topic: @topic, slack_thread: @thread,
                   draft_title: "Fix bug", draft_body: "Details")
  end

  test "update to dismissed marks item and topic" do
    patch action_item_path(@item), params: { status: "dismissed" }
    assert_redirected_to root_path
    assert_equal "dismissed", @item.reload.status
    assert_equal "dismissed", @topic.reload.status
  end

  test "dismissing last open topic archives the thread" do
    patch action_item_path(@item), params: { status: "dismissed" }
    assert_equal "archived", @thread.reload.status
  end

  test "dismissing does not archive thread when other open topics remain" do
    create(:slack_topic, slack_thread: @thread, status: "open", urgency: "medium")
    patch action_item_path(@item), params: { status: "dismissed" }
    assert_not_equal "archived", @thread.reload.status
  end

  test "update to resolved marks item resolved and topic actioned" do
    patch action_item_path(@item), params: { status: "resolved" }
    assert_redirected_to root_path
    assert_equal "resolved", @item.reload.status
    assert_equal "actioned", @topic.reload.status
  end

  test "resolving last open topic archives the thread" do
    patch action_item_path(@item), params: { status: "resolved" }
    assert_equal "archived", @thread.reload.status
  end

  test "update to pending restores item and reopens topic" do
    @item.update!(status: "ignored")
    @topic.update!(status: "dismissed")
    patch action_item_path(@item), params: { status: "pending" }
    assert_redirected_to root_path
    assert_equal "pending", @item.reload.status
    assert_equal "open", @topic.reload.status
  end
end
