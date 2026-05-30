require "test_helper"

class CodebaseAnalyses::NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread, slack_channel_id: "C123", slack_thread_ts: "123.456")
    @analysis = create(:codebase_analysis, slack_thread: @thread, status: :completed,
      draft_title: "Fix it", draft_body: "body",
      github_issue_url: "https://github.com/myorg/api/issues/42")
  end

  test "create posts issue URL to Slack thread" do
    calls = { post_message: [], add_reaction: [] }
    mock = Object.new
    mock.define_singleton_method(:configured?) { true }
    mock.define_singleton_method(:post_message) { |**kwargs| calls[:post_message] << kwargs }
    mock.define_singleton_method(:add_reaction) { |**kwargs| calls[:add_reaction] << kwargs }
    original_new = SlackService.method(:new)
    SlackService.define_singleton_method(:new) { |**_| mock }

    post slack_thread_codebase_analysis_notification_path(@thread, @analysis)
    assert_redirected_to slack_thread_path(@thread)
    assert_equal 1, calls[:post_message].size
  ensure
    SlackService.define_singleton_method(:new, original_new)
  end
end
