require "test_helper"

class PrReviews::AnalysesControllerTest < ActionDispatch::IntegrationTest
  test "new enqueues job when no cache exists" do
    mock = Object.new
    mock.define_singleton_method(:configured?) { true }
    mock.define_singleton_method(:pr_detail) { |*_| { head_sha: "abc123" } }
    original_gh = GitHubService.method(:new)
    GitHubService.define_singleton_method(:new) { |**_| mock }

    assert_enqueued_with(job: PrAnalysisJob) do
      get new_pr_reviews_analysis_path, params: { repo: "org/repo", pr_number: "42", pr_title: "Fix bug" }
    end
    assert_response :success
  ensure
    GitHubService.define_singleton_method(:new, original_gh)
  end

  test "new does not enqueue job when cache exists" do
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.write("pr_analysis/org/repo/42/abc123", { summary: "cached", recommendation: "approve" })

    mock = Object.new
    mock.define_singleton_method(:configured?) { true }
    mock.define_singleton_method(:pr_detail) { |*_| { head_sha: "abc123" } }
    original_gh = GitHubService.method(:new)
    GitHubService.define_singleton_method(:new) { |**_| mock }

    mock_pr = Object.new
    mock_pr.define_singleton_method(:claude_code_command) { |*_| "claude -p test" }
    original_pr = PrAnalysisService.method(:new)
    PrAnalysisService.define_singleton_method(:new) { |**_| mock_pr }

    assert_no_enqueued_jobs(only: PrAnalysisJob) do
      get new_pr_reviews_analysis_path, params: { repo: "org/repo", pr_number: "42", pr_title: "Fix bug" }
    end
    assert_response :success
  ensure
    GitHubService.define_singleton_method(:new, original_gh)
    PrAnalysisService.define_singleton_method(:new, original_pr)
    Rails.cache = ActiveSupport::Cache::NullStore.new
  end

  test "new does not enqueue job when already running" do
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.write("pr_analysis_running:org/repo:42", true)

    mock = Object.new
    mock.define_singleton_method(:configured?) { true }
    mock.define_singleton_method(:pr_detail) { |*_| { head_sha: "abc123" } }
    original_gh = GitHubService.method(:new)
    GitHubService.define_singleton_method(:new) { |**_| mock }

    assert_no_enqueued_jobs(only: PrAnalysisJob) do
      get new_pr_reviews_analysis_path, params: { repo: "org/repo", pr_number: "42", pr_title: "Fix bug" }
    end
    assert_response :success
  ensure
    GitHubService.define_singleton_method(:new, original_gh)
    Rails.cache = ActiveSupport::Cache::NullStore.new
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
