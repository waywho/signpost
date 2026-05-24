require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "show returns dashboard" do
    get root_path
    assert_response :success
    assert_select "h1", "Daily Lead Briefing"
  end
end
