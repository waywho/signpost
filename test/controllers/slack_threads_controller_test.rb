require "test_helper"

class SlackThreadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread)
  end

  test "should get index" do
    get slack_threads_path
    assert_response :success
  end

  test "should filter by category" do
    get slack_threads_path, params: { category: "architecture" }
    assert_response :success
  end

  test "should search by keyword" do
    get slack_threads_path, params: { q: "architecture" }
    assert_response :success
  end

  test "should get show" do
    get slack_thread_path(@thread)
    assert_response :success
  end

  test "should get new" do
    get new_slack_thread_path
    assert_response :success
  end

  test "should create slack_thread" do
    assert_difference("SlackThread.count") do
      post slack_threads_path, params: {
        slack_thread: {
          slack_channel_id: "C999",
          slack_thread_ts: "1700000000.000001",
          title: "New thread",
          category: "other"
        }
      }
    end
    assert_redirected_to slack_thread_path(SlackThread.last)
  end

  test "should not create without required fields" do
    assert_no_difference("SlackThread.count") do
      post slack_threads_path, params: {
        slack_thread: { title: "No channel or ts" }
      }
    end
    assert_response :unprocessable_entity
  end
end
