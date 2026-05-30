require "test_helper"

class SlackThreads::DelegationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread, title: "Important thread")
  end

  test "create redirects to new delegation with thread params" do
    post slack_thread_delegation_path(@thread)
    assert_response :redirect
    assert_match(/delegations\/new/, response.location)
  end
end
