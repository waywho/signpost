require "test_helper"

class SlackTopics::DelegationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread)
    @topic = create(:slack_topic, slack_thread: @thread, title: "Topic title", urgency: "high", category: "architecture")
  end

  test "create redirects to new delegation with topic params" do
    post slack_thread_slack_topic_delegation_path(@thread, @topic)
    assert_response :redirect
    assert_match(/delegations\/new/, response.location)
  end
end
