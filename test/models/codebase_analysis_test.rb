require "test_helper"

class CodebaseAnalysisTest < ActiveSupport::TestCase
  test "valid with required fields" do
    analysis = build(:codebase_analysis)
    assert analysis.valid?
  end

  test "invalid without repo_name" do
    analysis = build(:codebase_analysis, repo_name: nil)
    assert_not analysis.valid?
  end

  test "invalid without repo_path" do
    analysis = build(:codebase_analysis, repo_path: nil)
    assert_not analysis.valid?
  end

  test "default status is pending" do
    analysis = create(:codebase_analysis)
    assert_equal "pending", analysis.status
  end

  test "status enum values" do
    assert_equal({ "pending" => 0, "running" => 1, "completed" => 2, "failed" => 3 }, CodebaseAnalysis.statuses)
  end

  test "belongs to slack_thread" do
    analysis = create(:codebase_analysis)
    assert_kind_of SlackThread, analysis.slack_thread
  end

  test "delegation is optional" do
    analysis = build(:codebase_analysis, delegation: nil)
    assert analysis.valid?
  end

  test "slack_thread has_many codebase_analyses" do
    thread = create(:slack_thread)
    create(:codebase_analysis, slack_thread: thread)
    create(:codebase_analysis, slack_thread: thread, repo_name: "myorg/other")
    assert_equal 2, thread.codebase_analyses.count
  end

  test "destroying slack_thread destroys analyses" do
    thread = create(:slack_thread)
    create(:codebase_analysis, slack_thread: thread)
    assert_difference("CodebaseAnalysis.count", -1) { thread.destroy }
  end
end
