require "test_helper"

class SlackTopics::MergesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread)
    @topic1 = create(:slack_topic, slack_thread: @thread, title: "Bug A", summary: "First bug")
    @topic2 = create(:slack_topic, slack_thread: @thread, title: "Bug A variant", summary: "Same bug different angle")
  end

  test "merges two topics into one" do
    assert_difference("SlackTopic.count", -1) do
      post slack_thread_topic_merge_path(@thread), params: { topic_ids: [ @topic1.id, @topic2.id ] }
    end
    assert_redirected_to slack_thread_path(@thread)
    assert SlackTopic.exists?(@topic1.id)
    refute SlackTopic.exists?(@topic2.id)
  end

  test "moves action items to primary topic" do
    item = create(:action_item, slack_topic: @topic2, slack_thread: @thread)

    post slack_thread_topic_merge_path(@thread), params: { topic_ids: [ @topic1.id, @topic2.id ] }

    assert_equal @topic1, item.reload.slack_topic
  end

  test "rejects merge with less than 2 topics" do
    post slack_thread_topic_merge_path(@thread), params: { topic_ids: [ @topic1.id ] }
    assert_redirected_to slack_thread_path(@thread)
    assert_equal "Select at least 2 topics to merge.", flash[:alert]
  end
end
