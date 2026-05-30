require "test_helper"

class PrReviews::AnalysesControllerTest < ActionDispatch::IntegrationTest
  test "new renders analyze_pr page" do
    get new_pr_reviews_analysis_path, params: { repo: "org/repo", pr_number: "42", pr_title: "Fix bug" }
    assert_response :success
  end

  test "create re-analyzes existing pr_review" do
    pr_review = create(:pr_review)
    mock = Object.new
    mock.define_singleton_method(:analyze) { |**_| { summary: "test", recommendation: "approve" } }
    mock.define_singleton_method(:claude_code_command) { |*_| "claude -p test" }
    original_new = PrAnalysisService.method(:new)
    PrAnalysisService.define_singleton_method(:new) { |**_| mock }

    post pr_review_analysis_path(pr_review), as: :turbo_stream
    assert_response :success
  ensure
    PrAnalysisService.define_singleton_method(:new, original_new)
  end
end
