require "test_helper"

class SlackTopics::TicketDraftsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread)
    @topic = create(:slack_topic, slack_thread: @thread, title: "Fix login bug",
                    summary: "Login fails on mobile", urgency: "high", category: "bug")
  end

  test "create enqueues job and sets drafting flag" do
    assert_enqueued_with(job: TicketDraftJob, args: [ @topic.id ]) do
      post slack_thread_slack_topic_ticket_draft_path(@thread, @topic)
    end

    assert_redirected_to slack_thread_path(@thread)
    assert @topic.reload.drafting?
  end
end
