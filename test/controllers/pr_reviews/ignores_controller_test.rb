require "test_helper"

class PrReviews::IgnoresControllerTest < ActionDispatch::IntegrationTest
  test "create adds URL to ignored PRs" do
    post pr_reviews_ignore_path, params: { url: "https://github.com/org/repo/pull/1" }
    assert_response :redirect
    ignored = Setting.get("global", "ignored_prs", default: [])
    assert_includes ignored, "https://github.com/org/repo/pull/1"
  end
end
