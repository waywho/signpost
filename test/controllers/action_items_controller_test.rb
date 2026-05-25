require "test_helper"

class ActionItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread)
    @topic = create(:slack_topic, slack_thread: @thread, status: "open", urgency: "high")
    @item = create(:action_item, slack_topic: @topic, slack_thread: @thread,
                   draft_title: "Fix bug", draft_body: "Details")
  end

  test "approve creates delegation and marks approved" do
    assert_difference("Delegation.count") do
      post approve_action_item_path(@item)
    end
    assert_redirected_to root_path
    assert_equal "approved", @item.reload.status
    assert_equal "actioned", @topic.reload.status
    assert_not_nil @item.delegation_id
  end

  test "approve with developer assigns delegation" do
    dev = create(:developer)
    post approve_action_item_path(@item), params: { developer_id: dev.id }
    delegation = Delegation.last
    assert_equal dev, delegation.developer
    assert_equal dev.name, delegation.developer_name
  end

  test "dismiss marks item and topic dismissed" do
    post dismiss_action_item_path(@item)
    assert_redirected_to root_path
    assert_equal "dismissed", @item.reload.status
    assert_equal "dismissed", @topic.reload.status
  end
end
