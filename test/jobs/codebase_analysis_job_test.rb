require "test_helper"

class CodebaseAnalysisJobTest < ActiveSupport::TestCase
  test "finds record and calls service analyze" do
    analysis = create(:codebase_analysis)
    called_with_id = nil

    original_analyze = CodebaseAnalysisService.instance_method(:analyze)
    CodebaseAnalysisService.define_method(:analyze) { |a| called_with_id = a.id }

    CodebaseAnalysisJob.perform_now(analysis.id)

    assert_equal analysis.id, called_with_id
  ensure
    CodebaseAnalysisService.define_method(:analyze, original_analyze)
  end

  test "broadcasts on completion" do
    analysis = create(:codebase_analysis, status: :pending)

    original_analyze = CodebaseAnalysisService.instance_method(:analyze)
    CodebaseAnalysisService.define_method(:analyze) do |a|
      a.update!(status: :completed, analysis: "Found it", draft_title: "Fix", draft_body: "Details", completed_at: Time.current)
    end

    CodebaseAnalysisJob.perform_now(analysis.id)
    assert_equal "completed", analysis.reload.status
  ensure
    CodebaseAnalysisService.define_method(:analyze, original_analyze)
  end

  test "broadcasts on failure" do
    analysis = create(:codebase_analysis, status: :pending)

    original_analyze = CodebaseAnalysisService.instance_method(:analyze)
    CodebaseAnalysisService.define_method(:analyze) do |a|
      a.update!(status: :failed, error_message: "Claude unavailable", completed_at: Time.current)
    end

    CodebaseAnalysisJob.perform_now(analysis.id)
    assert_equal "failed", analysis.reload.status
  ensure
    CodebaseAnalysisService.define_method(:analyze, original_analyze)
  end
end
