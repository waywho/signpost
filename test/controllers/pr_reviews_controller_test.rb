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
    get pr_reviews_path, params: { recommendation: "APPROVE" }
    assert_response :success
  end

  test "should get show" do
    get pr_review_path(@pr_review)
    assert_response :success
  end

  test "should get new" do
    get new_pr_review_path
    assert_response :success
  end

  test "should create pr_review" do
    assert_difference("PrReview.count") do
      post pr_reviews_path, params: { pr_review: { pr_number: 99, repo: "org/repo", recommendation: "APPROVE" } }
    end
    assert_redirected_to pr_review_path(PrReview.last)
  end

  test "should not create without required fields" do
    assert_no_difference("PrReview.count") do
      post pr_reviews_path, params: { pr_review: { pr_number: nil, repo: "" } }
    end
    assert_response :unprocessable_entity
  end
end
