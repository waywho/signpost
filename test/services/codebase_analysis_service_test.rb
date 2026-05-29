require "test_helper"

class CodebaseAnalysisServiceTest < ActiveSupport::TestCase
  setup do
    @thread = create(:slack_thread, title: "Login bug", summary: "Users can't log in after OAuth redirect")
    create(:slack_message, slack_thread: @thread, user_name: "Alice", content: "Login is broken after the OAuth change")
    create(:slack_topic, slack_thread: @thread, title: "OAuth redirect bug", summary: "OAuth flow breaks on callback", urgency: "high", category: "bug")
    @analysis = create(:codebase_analysis, slack_thread: @thread, repo_name: "myorg/api", repo_path: "/tmp/test-repo")
  end

  test "analyze sets status to completed with draft extracted" do
    claude_output = <<~OUTPUT
      ## Analysis
      Found the issue in app/controllers/sessions_controller.rb. The OAuth callback doesn't handle the state parameter.

      ## Draft Issue
      TITLE: Fix OAuth callback state parameter handling
      BODY:
      ## Context
      OAuth login fails after redirect.

      ## Problem
      State parameter not validated in callback.

      ## Acceptance Criteria
      - [ ] OAuth login works end to end
    OUTPUT

    service = build_service(stdout: claude_output)
    service.analyze(@analysis)

    @analysis.reload
    assert_equal "completed", @analysis.status
    assert_equal "Fix OAuth callback state parameter handling", @analysis.draft_title
    assert_includes @analysis.draft_body, "OAuth login fails"
    assert @analysis.started_at.present?
    assert @analysis.completed_at.present?
    assert @analysis.analysis.present?
    assert @analysis.prompt_context.present?
  end

  test "analyze sets status to failed on CLI error" do
    service = build_service(stdout: "", stderr: "claude: command not found", success: false)
    service.analyze(@analysis)

    @analysis.reload
    assert_equal "failed", @analysis.status
    assert_includes @analysis.error_message, "Claude CLI failed"
    assert @analysis.completed_at.present?
  end

  test "prompt includes thread title, summary, messages, and topics" do
    service = build_service(stdout: "## Analysis\nNothing found.\n\n## Draft Issue\nTITLE: Test\nBODY:\nTest body")
    service.analyze(@analysis)

    prompt = @analysis.reload.prompt_context
    assert_includes prompt, "Login bug"
    assert_includes prompt, "Users can't log in"
    assert_includes prompt, "Alice"
    assert_includes prompt, "Login is broken"
    assert_includes prompt, "OAuth redirect bug"
  end

  test "extract_draft falls back when format not matched" do
    output = "I looked at the code and found a bug in the auth module."

    service = build_service(stdout: output)
    service.analyze(@analysis)

    @analysis.reload
    assert_equal "completed", @analysis.status
    assert_equal "Untitled", @analysis.draft_title
    assert_equal output, @analysis.draft_body
  end

  private

  def build_service(stdout: "", stderr: "", success: true)
    service = CodebaseAnalysisService.new
    status = Struct.new(:success?).new(success)
    service.define_singleton_method(:run_claude) do |prompt, directory:|
      raise "Claude CLI failed: #{(stderr.presence || stdout).truncate(500)}" unless status.success?
      stdout.strip
    end
    service
  end
end
