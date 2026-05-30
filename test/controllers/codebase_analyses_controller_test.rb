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

end
