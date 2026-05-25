require "test_helper"

class DailyLogsControllerTest < ActionDispatch::IntegrationTest
  test "should create daily log" do
    DailyLog.where(log_date: Date.current).destroy_all
    post daily_logs_path, params: { daily_log: { eod_notes: "Shipped feature", tomorrow_priorities: ["Review PRs"] } }
    assert_redirected_to root_path
    log = DailyLog.find_by(log_date: Date.current)
    assert_equal "Shipped feature", log.eod_notes
  end

  test "should update existing daily log" do
    log = create(:daily_log, log_date: Date.current)
    patch daily_log_path(log), params: { daily_log: { eod_notes: "Updated notes" } }
    assert_redirected_to root_path
    assert_equal "Updated notes", log.reload.eod_notes
  end
end
