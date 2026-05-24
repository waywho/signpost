class SlackCaptureJob < ApplicationJob
  queue_as :default

  def perform(channel_id:, thread_ts:, capture_reason:)
    SlackCaptureService.new.capture(
      channel_id: channel_id,
      thread_ts: thread_ts,
      capture_reason: capture_reason
    )
  end
end
