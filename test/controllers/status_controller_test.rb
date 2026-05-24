require "test_helper"

class StatusControllerTest < ActionDispatch::IntegrationTest
  test "show returns service status" do
    get status_path
    assert_response :success
    assert_select "h1", "System Status"
  end
end
