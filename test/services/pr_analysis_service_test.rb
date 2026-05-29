require "test_helper"
require "ostruct"

class PrAnalysisServiceTest < ActiveSupport::TestCase
  test "analyze returns parsed analysis" do
    mock_github = Object.new
    mock_github.define_singleton_method(:pr_detail) { |repo, number| { number: 1, title: "Fix", author: "alice", body: "Fixes #1", additions: 10, deletions: 5, changed_files: 2 } }
    mock_github.define_singleton_method(:pr_diff) { |repo, number| "+added line\n-removed line" }
    mock_github.define_singleton_method(:pr_comments) { |repo, number| [] }
    mock_github.define_singleton_method(:linked_issue) { |repo, number| nil }

    analysis_json = {
      recommendation: "approve",
      recommendation_reason: "Clean implementation",
      summary: "Adds feature X",
      critical_flags: [],
      strengths: ["Good test coverage"],
      issues: { critical: [], important: [], minor: [] },
      solves_ticket: { result: "yes", explanation: "Matches description" },
      risk_areas: [],
      missing_tests: [],
      performance_concerns: [],
      security_issues: [],
      before_review_tips: ["Check the migration"],
      inline_tips: [],
      after_checklist: [{ item: "Run migrations", why: "Schema change" }],
      draft_comment: "LGTM"
    }.to_json

    mock_claude = Object.new
    mock_claude.define_singleton_method(:analyze) { |prompt, **_| analysis_json }

    service = PrAnalysisService.new(github_service: mock_github, claude_service: mock_claude)
    result = service.analyze(repo: "org/repo", pr_number: 1)

    assert_equal "approve", result[:recommendation]
    assert_includes result[:strengths], "Good test coverage"
  end

  test "handles JSON parse failure gracefully" do
    mock_github = Object.new
    mock_github.define_singleton_method(:pr_detail) { |repo, number| { number: 1, title: "Fix", author: "alice", body: "", additions: 0, deletions: 0, changed_files: 0 } }
    mock_github.define_singleton_method(:pr_diff) { |repo, number| "" }
    mock_github.define_singleton_method(:pr_comments) { |repo, number| [] }
    mock_github.define_singleton_method(:linked_issue) { |repo, number| nil }

    mock_claude = Object.new
    mock_claude.define_singleton_method(:analyze) { |prompt, **_| "not valid json" }

    service = PrAnalysisService.new(github_service: mock_github, claude_service: mock_claude)
    result = service.analyze(repo: "org/repo", pr_number: 1)

    assert result[:parse_error]
  end

  test "claude_code_command generates terminal command" do
    pr_review = OpenStruct.new(pr_number: 42, pr_title: "Fix bug", repo: "org/repo")
    service = PrAnalysisService.new
    cmd = service.claude_code_command(pr_review, ["app/models/user.rb"])

    assert_includes cmd, "#42"
    assert_includes cmd, "app/models/user.rb"
    assert_includes cmd, "CLAUDE.md"
  end
end
