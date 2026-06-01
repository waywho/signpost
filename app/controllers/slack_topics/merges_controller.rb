class SlackTopics::MergesController < ApplicationController
  def create
    @slack_thread = SlackThread.find(params[:slack_thread_id])
    topic_ids = Array(params[:topic_ids]).reject(&:blank?)

    if topic_ids.size < 2
      redirect_to @slack_thread, alert: "Select at least 2 topics to merge."
      return
    end

    topics = @slack_thread.slack_topics.where(id: topic_ids).order(:created_at)
    primary = topics.first
    others = topics.drop(1)

    ActiveRecord::Base.transaction do
      others.each do |topic|
        # Move messages to primary
        topic.slack_topic_messages.update_all(slack_topic_id: primary.id)

        # Move action items to primary
        topic.action_items.update_all(slack_topic_id: primary.id)

        topic.destroy!
      end

      # Update primary summary to reflect merged content
      primary.update!(
        summary: "#{primary.summary} (merged #{others.size} related #{'topic'.pluralize(others.size)})"
      )
    end

    redirect_to @slack_thread, notice: "Merged #{topics.size} topics into \"#{primary.title}\"."
  end
end
