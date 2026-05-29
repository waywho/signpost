require "test_helper"

class CodebaseAnalysesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread, slack_channel_id: "C123", slack_thread_ts: "123.456")
    Setting.set("global", "repo_paths", { "myorg/api" => "/tmp/test-repo" })
  end

  # -- create --

  test "create enqueues analysis job and redirects" do
    assert_difference("CodebaseAnalysis.count") do
      post slack_thread_codebase_analyses_path(@thread), params: { repo_name: "myorg/api" }
    end

    analysis = CodebaseAnalysis.last
    assert_equal "myorg/api", analysis.repo_name
    assert_equal "/tmp/test-repo", analysis.repo_path
    assert_equal "pending", analysis.status
    assert_redirected_to slack_thread_path(@thread)
  end

  test "create rejects unknown repo" do
    assert_no_difference("CodebaseAnalysis.count") do
      post slack_thread_codebase_analyses_path(@thread), params: { repo_name: "unknown/repo" }
    end
    assert_redirected_to slack_thread_path(@thread)
    assert_equal "Unknown repo: unknown/repo", flash[:alert]
  end

  # -- show --

  test "show renders for pending analysis" do
    analysis = create(:codebase_analysis, slack_thread: @thread, status: :pending)
    get slack_thread_codebase_analysis_path(@thread, analysis)
    assert_response :success
  end

  test "show renders for completed analysis" do
    analysis = create(:codebase_analysis, slack_thread: @thread, status: :completed,
      analysis: "Found the bug", draft_title: "Fix it", draft_body: "## Details")
    get slack_thread_codebase_analysis_path(@thread, analysis)
    assert_response :success
  end

  # -- create_issue --

  test "create_issue creates GitHub issue and stores URL" do
    analysis = create(:codebase_analysis, slack_thread: @thread, status: :completed,
      draft_title: "Fix OAuth bug", draft_body: "## Context\nOAuth is broken")

    with_mock_github(
      create_issue_result: { number: 42, url: "https://github.com/myorg/api/issues/42", title: "Fix OAuth bug" }
    ) do
      post create_issue_slack_thread_codebase_analysis_path(@thread, analysis), params: { repo: "myorg/api" }
    end

    analysis.reload
    assert_equal "https://github.com/myorg/api/issues/42", analysis.github_issue_url
    assert_redirected_to slack_thread_path(@thread)
  end

  # -- delegate --

  test "delegate creates delegation and links to analysis" do
    analysis = create(:codebase_analysis, slack_thread: @thread, status: :completed,
      draft_title: "Fix OAuth bug", draft_body: "body")
    developer = create(:developer, name: "Bob")

    assert_difference("Delegation.count") do
      post delegate_slack_thread_codebase_analysis_path(@thread, analysis),
        params: { developer_id: developer.id }
    end

    analysis.reload
    assert analysis.delegation.present?
    assert_equal "Fix OAuth bug", analysis.delegation.summary
    assert_equal developer, analysis.delegation.developer
    assert_redirected_to slack_thread_path(@thread)
  end

  test "delegate with notify_thread posts to Slack" do
    analysis = create(:codebase_analysis, slack_thread: @thread, status: :completed,
      draft_title: "Fix it", draft_body: "body")
    developer = create(:developer, name: "Bob", slack_handle: "U123BOB")

    calls = with_mock_slack do
      post delegate_slack_thread_codebase_analysis_path(@thread, analysis),
        params: { developer_id: developer.id, notify_thread: "1" }
    end

    assert_equal 1, calls[:post_message].size
    assert_equal "<@U123BOB> Can you take a look?", calls[:post_message].first[:text]
  end

  # -- notify --

  test "notify posts issue URL to Slack thread" do
    analysis = create(:codebase_analysis, slack_thread: @thread, status: :completed,
      draft_title: "Fix it", draft_body: "body",
      github_issue_url: "https://github.com/myorg/api/issues/42")

    calls = with_mock_slack do
      post notify_slack_thread_codebase_analysis_path(@thread, analysis)
    end

    assert_equal 1, calls[:post_message].size
    assert_equal "https://github.com/myorg/api/issues/42", calls[:post_message].first[:text]
    assert_redirected_to slack_thread_path(@thread)
  end

  test "notify adds eyes reaction when no URL" do
    analysis = create(:codebase_analysis, slack_thread: @thread, status: :completed,
      draft_title: "Fix it", draft_body: "body")

    calls = with_mock_slack do
      post notify_slack_thread_codebase_analysis_path(@thread, analysis)
    end

    assert_equal 1, calls[:add_reaction].size
    assert_equal "eyes", calls[:add_reaction].first[:emoji]
  end

  # -- dismiss --

  test "dismiss destroys analysis and redirects" do
    analysis = create(:codebase_analysis, slack_thread: @thread)
    assert_difference("CodebaseAnalysis.count", -1) do
      post dismiss_slack_thread_codebase_analysis_path(@thread, analysis)
    end
    assert_redirected_to slack_thread_path(@thread)
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

  def with_mock_github(create_issue_result:)
    mock = Object.new
    mock.define_singleton_method(:create_issue) { |*_args, **_kwargs| create_issue_result }

    original_new = GitHubService.method(:new)
    GitHubService.define_singleton_method(:new) { |**_| mock }
    yield
  ensure
    GitHubService.define_singleton_method(:new, original_new)
  end
end
