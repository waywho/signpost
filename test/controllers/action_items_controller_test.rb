require "test_helper"

class ActionItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread)
    @topic = create(:slack_topic, slack_thread: @thread, status: "open", urgency: "high")
    @item = create(:action_item, slack_topic: @topic, slack_thread: @thread,
                   draft_title: "Fix bug", draft_body: "Details")
  end

  test "act creates delegation and marks actioned" do
    assert_difference("Delegation.count") do
      post act_action_item_path(@item)
    end
    assert_redirected_to root_path
    assert_equal "actioned", @item.reload.status
    assert_equal "actioned", @topic.reload.status
    assert_not_nil @item.delegation_id
  end

  test "act with developer assigns delegation" do
    dev = create(:developer)
    post act_action_item_path(@item), params: { developer_id: dev.id }
    delegation = Delegation.last
    assert_equal dev, delegation.developer
    assert_equal dev.name, delegation.developer_name
  end

  test "act with existing issue URL stores it" do
    post act_action_item_path(@item), params: { existing_issue_url: "https://github.com/org/repo/issues/42" }
    @item.reload
    assert_equal "https://github.com/org/repo/issues/42", @item.github_issue_url
    assert_equal "https://github.com/org/repo/issues/42", Delegation.last.github_issue_url
  end

  test "act with notify_thread and developer posts message" do
    dev = create(:developer, slack_handle: "U12345")
    calls = with_mock_slack do
      post act_action_item_path(@item), params: { developer_id: dev.id, notify_thread: "1" }
    end
    assert_redirected_to root_path
    assert_equal 1, calls[:post_message].size
    assert_equal "<@U12345> Can you take a look?", calls[:post_message].first[:text]
  end

  test "act with notify_thread and ticket posts message with link" do
    dev = create(:developer, slack_handle: "U12345")
    calls = with_mock_slack do
      post act_action_item_path(@item), params: {
        developer_id: dev.id, notify_thread: "1",
        existing_issue_url: "https://github.com/org/repo/issues/42"
      }
    end
    assert_equal "<@U12345> Can you take a look?\nhttps://github.com/org/repo/issues/42", calls[:post_message].first[:text]
  end

  test "act with notify_thread no developer no ticket adds emoji" do
    calls = with_mock_slack do
      post act_action_item_path(@item), params: { developer_id: "", notify_thread: "1" }
    end
    assert_equal 1, calls[:add_reaction].size
    assert_equal "eyes", calls[:add_reaction].first[:emoji]
  end

  test "act with notify_thread no developer but ticket posts ticket message" do
    calls = with_mock_slack do
      post act_action_item_path(@item), params: {
        developer_id: "", notify_thread: "1",
        existing_issue_url: "https://github.com/org/repo/issues/42"
      }
    end
    assert_equal "A ticket is created:\nhttps://github.com/org/repo/issues/42", calls[:post_message].first[:text]
  end

  test "update to dismissed marks item and topic" do
    patch action_item_path(@item), params: { status: "dismissed" }
    assert_redirected_to root_path
    assert_equal "dismissed", @item.reload.status
    assert_equal "dismissed", @topic.reload.status
  end

  test "update to resolved marks item resolved and topic actioned" do
    patch action_item_path(@item), params: { status: "resolved" }
    assert_redirected_to root_path
    assert_equal "resolved", @item.reload.status
    assert_equal "actioned", @topic.reload.status
  end

  test "update to pending restores item and reopens topic" do
    @item.update!(status: "ignored")
    @topic.update!(status: "dismissed")
    patch action_item_path(@item), params: { status: "pending" }
    assert_redirected_to root_path
    assert_equal "pending", @item.reload.status
    assert_equal "open", @topic.reload.status
  end

  private

  def with_mock_slack
    calls = { post_message: [], add_reaction: [] }
    mock = Object.new
    mock.define_singleton_method(:configured?) { true }
    mock.define_singleton_method(:post_message) { |**kwargs| calls[:post_message] << kwargs }
    mock.define_singleton_method(:add_reaction) { |**kwargs| calls[:add_reaction] << kwargs }

    original_new = SlackService.method(:new)
    SlackService.define_singleton_method(:new) { |**_| mock }
    yield
    calls
  ensure
    SlackService.define_singleton_method(:new, original_new)
  end
end
