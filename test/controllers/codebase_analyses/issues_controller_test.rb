require "test_helper"

class CodebaseAnalyses::IssuesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread, slack_channel_id: "C123", slack_thread_ts: "123.456")
    @analysis = create(:codebase_analysis, slack_thread: @thread, status: :completed,
      draft_title: "Fix OAuth bug", draft_body: "## Context\nOAuth is broken")
  end

  test "create creates GitHub issue and stores URL" do
    mock = Object.new
    mock.define_singleton_method(:create_issue) { |*_args, **_kwargs|
      { number: 42, url: "https://github.com/myorg/api/issues/42", title: "Fix OAuth bug" }
    }
    original_new = GitHubService.method(:new)
    GitHubService.define_singleton_method(:new) { |**_| mock }

    post slack_thread_codebase_analysis_issue_path(@thread, @analysis), params: { repo: "myorg/api" }
    assert_redirected_to slack_thread_path(@thread)
    assert_equal "https://github.com/myorg/api/issues/42", @analysis.reload.github_issue_url
  ensure
    GitHubService.define_singleton_method(:new, original_new)
  end
end
