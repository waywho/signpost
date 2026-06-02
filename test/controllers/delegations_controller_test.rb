require "test_helper"

class DelegationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @delegation = create(:delegation)
  end

  test "should get index" do
    get delegations_path
    assert_response :success
  end

  test "should filter by status" do
    get delegations_path, params: { status: "delegated" }
    assert_response :success
  end

  test "should get show" do
    get delegation_path(@delegation)
    assert_response :success
  end

  test "should get new" do
    get new_delegation_path
    assert_response :success
  end

  test "should create delegation" do
    assert_difference("Delegation.count") do
      post delegations_path, params: { delegation: { summary: "New task", urgency: "high", status: "delegated" } }
    end
    assert_redirected_to delegation_path(Delegation.last)
  end

  test "should action source topic and action items when slack_topic_id provided" do
    thread = create(:slack_thread)
    topic = create(:slack_topic, slack_thread: thread, status: "open", urgency: "high")
    item = create(:action_item, slack_topic: topic, slack_thread: thread,
                  draft_title: "Fix", draft_body: "Details")

    post delegations_path, params: {
      delegation: { summary: "Delegated task", urgency: "high", status: "delegated" },
      slack_topic_id: topic.id
    }

    assert_equal "actioned", topic.reload.status
    assert_equal "actioned", item.reload.status
  end

  test "should not create without summary" do
    assert_no_difference("Delegation.count") do
      post delegations_path, params: { delegation: { summary: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "should update status to done and set resolved_at" do
    patch delegation_path(@delegation), params: { delegation: { status: "done" } }
    assert_redirected_to delegation_path(@delegation)
    assert_not_nil @delegation.reload.resolved_at
  end

  test "should destroy" do
    assert_difference("Delegation.count", -1) do
      delete delegation_path(@delegation)
    end
    assert_redirected_to delegations_path
  end
end
