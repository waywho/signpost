require "test_helper"

class CodebaseAnalyses::DismissalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread)
    @analysis = create(:codebase_analysis, slack_thread: @thread)
  end

  test "destroy destroys analysis and redirects" do
    assert_difference("CodebaseAnalysis.count", -1) do
      delete slack_thread_codebase_analysis_dismissal_path(@thread, @analysis)
    end
    assert_redirected_to slack_thread_path(@thread)
  end
end
