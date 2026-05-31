require "test_helper"

class PrReviews::AnalysesControllerTest < ActionDispatch::IntegrationTest
  test "create enqueues job and redirects" do
    pr_review = create(:pr_review)

    assert_enqueued_with(job: PrAnalysisJob) do
      post pr_review_analysis_path(pr_review)
    end
    assert_redirected_to pr_review_path(pr_review)
  end
end
