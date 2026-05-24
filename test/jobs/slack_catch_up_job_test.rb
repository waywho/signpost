require "test_helper"

class SlackCatchUpJobTest < ActiveSupport::TestCase
  test "skips when mode is poll only" do
    Setting.set("global", "slack_capture_mode", "poll")
    assert_nothing_raised { SlackCatchUpJob.perform_now }
  end

  test "runs when mode is socket" do
    Setting.set("global", "slack_capture_mode", "socket")
    assert_nothing_raised { SlackCatchUpJob.perform_now }
  end
end
