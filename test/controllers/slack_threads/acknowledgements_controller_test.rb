require "test_helper"

class SlackThreads::AcknowledgementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread)
  end

  test "create acknowledges thread" do
    mock = Object.new
    mock.define_singleton_method(:configured?) { true }
    mock.define_singleton_method(:add_reaction) { |**_| nil }
    original_new = SlackService.method(:new)
    SlackService.define_singleton_method(:new) { |**_| mock }

    post slack_thread_acknowledgement_path(@thread)
    assert_redirected_to slack_threads_path
    assert_equal "triaged", @thread.reload.status
  ensure
    SlackService.define_singleton_method(:new, original_new)
  end
end
