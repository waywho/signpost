require "test_helper"

class Dashboard::SectionsControllerTest < ActionDispatch::IntegrationTest
  test "action_queue renders" do
    get dashboard_action_queue_path
    assert_response :success
  end

  test "insights renders" do
    get dashboard_insights_path
    assert_response :success
  end

  test "calendar renders" do
    get dashboard_calendar_path
    assert_response :success
  end

  test "team_overview renders" do
    get dashboard_team_overview_path
    assert_response :success
  end

  test "active_delegations renders" do
    get dashboard_active_delegations_path
    assert_response :success
  end

  test "commitments renders" do
    get dashboard_commitments_path
    assert_response :success
  end

  test "pr_reviews renders" do
    get dashboard_pr_reviews_path
    assert_response :success
  end

  test "daily_log renders" do
    get dashboard_daily_log_path
    assert_response :success
  end
end
