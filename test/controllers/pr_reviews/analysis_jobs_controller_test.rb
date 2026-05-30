require "test_helper"

class PrReviews::AnalysisJobsControllerTest < ActionDispatch::IntegrationTest
  test "create enqueues analysis job" do
    assert_enqueued_with(job: PrAnalysisJob) do
      post pr_reviews_analysis_job_path, params: { repo: "org/repo", pr_number: "42" }
    end
    assert_response :redirect
  end
end
