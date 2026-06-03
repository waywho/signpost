class TicketDraftJob < ApplicationJob
  queue_as :default

  def perform(slack_topic_id)
    topic = SlackTopic.find(slack_topic_id)
    thread = topic.slack_thread

    draft = TicketDraftService.new.draft(topic)

    delegation = Delegation.create!(
      summary: draft[:title],
      handoff_message: draft[:body],
      urgency: topic.urgency,
      issue_type: topic.category,
      slack_topic: topic,
      slack_channel_id: thread.slack_channel_id,
      slack_thread_ts: thread.slack_thread_ts,
      status: "delegated",
      delegated_at: Time.current
    )

    topic.update!(status: "actioned", drafting: false)
    topic.action_items.pending.update_all(status: "actioned", actioned_at: Time.current)

    broadcast_topic(topic, delegation)
  rescue => e
    topic = SlackTopic.find_by(id: slack_topic_id)
    topic&.update!(drafting: false)
    Rails.logger.error("TicketDraftJob failed for topic #{slack_topic_id}: #{e.message}")
  end

  private

  def broadcast_topic(topic, delegation)
    Turbo::StreamsChannel.broadcast_replace_to(
      topic.slack_thread,
      target: "topic_#{topic.id}",
      partial: "slack_threads/topic",
      locals: { topic:, delegation: }
    )
  end
end
