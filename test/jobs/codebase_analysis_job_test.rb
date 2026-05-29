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
end
