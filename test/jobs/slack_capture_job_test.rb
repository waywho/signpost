require "test_helper"

class SlackCaptureJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "enqueues successfully" do
    assert_enqueued_with(job: SlackCaptureJob) do
      SlackCaptureJob.perform_later(channel_id: "C1", thread_ts: "1.1", capture_reason: "manual")
    end
  end
end
