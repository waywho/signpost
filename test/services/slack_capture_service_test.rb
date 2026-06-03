require "test_helper"
require "ostruct"

# Stub for Task 5 (not yet implemented)
class ThreadAnalysisJob < ApplicationJob
  def perform(*); end
end unless defined?(ThreadAnalysisJob)

class SlackCaptureServiceTest < ActiveSupport::TestCase
  setup do
    @embedding = Array.new(1536, 0.1)

    @mock_slack = Object.new
    @mock_embedder = Object.new
    @mock_noise = Object.new

    def @mock_embedder.embed(text) = Array.new(1536, 0.1)
    def @mock_noise.noise?(text) = false

    @service = SlackCaptureService.new(
      slack_client: @mock_slack,
      embedding_service: @mock_embedder,
      noise_filter_service: @mock_noise
    )
  end

  test "captures new thread with messages" do
    def @mock_slack.conversations_info(channel:) = OpenStruct.new(channel: OpenStruct.new(name: "eng"))
    def @mock_slack.conversations_replies(channel:, ts:, limit:)
      OpenStruct.new(messages: [
        { "ts" => "1.1", "text" => "hello", "user" => "U1" },
        { "ts" => "1.2", "text" => "world", "user" => "U2" }
      ])
    end
    def @mock_slack.users_info(user:)
      name = user == "U1" ? "Alice" : "Bob"
      OpenStruct.new(user: OpenStruct.new(real_name: name))
    end

    thread = @service.capture(channel_id: "CNEW1", thread_ts: "1.0", capture_reason: "brain_emoji")

    assert_equal "eng", thread.slack_channel_name
    assert_equal "brain_emoji", thread.capture_reason
    assert_equal 2, thread.slack_messages.count
  end

  test "skips duplicate messages" do
    existing = create(:slack_thread)
    existing.slack_messages.create!(message_ts: "99.1", content: "already here", embedding: @embedding)

    def @mock_slack.conversations_replies(channel:, ts:, limit:)
      OpenStruct.new(messages: [ { "ts" => "99.1", "text" => "already here", "user" => "U1" } ])
    end

    assert_no_difference("SlackMessage.count") do
      @service.capture(channel_id: existing.slack_channel_id, thread_ts: existing.slack_thread_ts, capture_reason: "manual")
    end
  end

  test "skips thread when first message is a PR review request" do
    def @mock_slack.conversations_replies(channel:, ts:, limit:)
      OpenStruct.new(messages: [
        { "ts" => "70.1", "text" => "someone requested your review on PR #42", "user" => "U1" },
        { "ts" => "70.2", "text" => "looks good, approved", "user" => "U2" }
      ])
    end

    result = @service.capture(channel_id: "CPR1", thread_ts: "70.0", capture_reason: "mention")
    assert_nil result
  end

  test "skips noise messages" do
    def @mock_noise.noise?(text) = true

    def @mock_slack.conversations_info(channel:) = OpenStruct.new(channel: OpenStruct.new(name: "eng"))
    def @mock_slack.conversations_replies(channel:, ts:, limit:)
      OpenStruct.new(messages: [ { "ts" => "50.1", "text" => "deploy v1.0", "user" => "U1" } ])
    end

    @service = SlackCaptureService.new(
      slack_client: @mock_slack,
      embedding_service: @mock_embedder,
      noise_filter_service: @mock_noise
    )

    assert_no_difference("SlackMessage.count") do
      @service.capture(channel_id: "CNOISE", thread_ts: "50.0", capture_reason: "channel_stream")
    end
  end
end
