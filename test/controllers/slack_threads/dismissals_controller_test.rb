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
end
