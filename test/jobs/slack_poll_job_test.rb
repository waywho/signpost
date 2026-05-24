require "test_helper"

class SlackPollJobTest < ActiveSupport::TestCase
  test "skips when mode is socket only" do
    Setting.set("global", "slack_capture_mode", "socket")
    assert_nothing_raised { SlackPollJob.perform_now }
  end

  test "runs when mode is poll" do
    Setting.set("global", "slack_capture_mode", "poll")
    assert_nothing_raised { SlackPollJob.perform_now }
  end

  test "runs when mode is both" do
    Setting.set("global", "slack_capture_mode", "both")
    assert_nothing_raised { SlackPollJob.perform_now }
  end
end
