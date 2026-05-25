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
end
