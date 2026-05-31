require "test_helper"

class PrReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pr_review = create(:pr_review)
  end

  test "should get index" do
    get pr_reviews_path
    assert_response :success
  end

  test "should filter by repo" do
    get pr_reviews_path, params: { repo: "myorg/myapp" }
    assert_response :success
  end

  test "should filter by recommendation" do
    get pr_reviews_path, params: { recommendation: "approve" }
    assert_response :success
  end

  test "should get show" do
    get pr_review_path(@pr_review)
    assert_response :success
  end

  test "show loads cached analysis" do
    pr = create(:pr_review, repo: "org/repo", pr_number: 99, head_sha: "sha123")
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.write("pr_analysis/org/repo/99/sha123", { summary: "cached", recommendation: "approve", risk_areas: [] })

    get pr_review_path(pr)
    assert_response :success
  ensure
    Rails.cache = original_cache
  end

  test "show auto-enqueues job when no cache" do
    pr = create(:pr_review, repo: "org/repo", pr_number: 99, head_sha: "sha123")

    mock_gh = Object.new
    mock_gh.define_singleton_method(:configured?) { true }
    original_gh = GitHubService.method(:new)
    GitHubService.define_singleton_method(:new) { |**_| mock_gh }

    mock_claude = Object.new
    mock_claude.define_singleton_method(:configured?) { true }
    original_claude = ClaudeService.method(:new)
    ClaudeService.define_singleton_method(:new) { |**_| mock_claude }

    assert_enqueued_with(job: PrAnalysisJob) do
      get pr_review_path(pr)
    end
    assert_response :success
  ensure
    GitHubService.define_singleton_method(:new, original_gh)
    ClaudeService.define_singleton_method(:new, original_claude)
  end

  test "show does not enqueue when job already running" do
    pr = create(:pr_review, repo: "org/repo", pr_number: 99, head_sha: "sha123")
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.write("pr_analysis_running:org/repo:99", true)

    mock_gh = Object.new
    mock_gh.define_singleton_method(:configured?) { true }
    original_gh = GitHubService.method(:new)
    GitHubService.define_singleton_method(:new) { |**_| mock_gh }

    mock_claude = Object.new
    mock_claude.define_singleton_method(:configured?) { true }
    original_claude = ClaudeService.method(:new)
    ClaudeService.define_singleton_method(:new) { |**_| mock_claude }

    assert_no_enqueued_jobs(only: PrAnalysisJob) do
      get pr_review_path(pr)
    end
    assert_response :success
  ensure
    GitHubService.define_singleton_method(:new, original_gh)
    ClaudeService.define_singleton_method(:new, original_claude)
    Rails.cache = original_cache
  end
end
