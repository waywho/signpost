require "test_helper"

class TicketDraftJobTest < ActiveSupport::TestCase
  setup do
    @thread = create(:slack_thread)
    @topic = create(:slack_topic, slack_thread: @thread, title: "Fix login bug",
                    summary: "Login fails on mobile", urgency: "high", category: "bug",
                    drafting: true)
    @item = create(:action_item, slack_topic: @topic, slack_thread: @thread,
                   draft_title: "Fix", draft_body: "Details")
  end

  test "creates delegation and actions topic" do
    mock_claude = Object.new
    mock_claude.define_singleton_method(:analyze) { |_prompt, **_opts|
      '{"title":"Fix login bug","body":"## Context\nLogin fails","suggested_repo":"app"}'
    }
    service = TicketDraftService.new(claude_service: mock_claude)
    original_new = TicketDraftService.method(:new)
    TicketDraftService.define_singleton_method(:new) { |**_| service }

    assert_difference "Delegation.count", 1 do
      TicketDraftJob.perform_now(@topic.id)
    end

    delegation = Delegation.last
    assert_equal "Fix login bug", delegation.summary
    assert_equal "## Context\nLogin fails", delegation.handoff_message
    assert_equal "high", delegation.urgency
    assert_equal "bug", delegation.issue_type

    @topic.reload
    assert_equal "actioned", @topic.status
    assert_not @topic.drafting?
    assert_equal "actioned", @item.reload.status
  ensure
    TicketDraftService.define_singleton_method(:new, original_new)
  end

  test "clears drafting flag on failure" do
    mock_claude = Object.new
    mock_claude.define_singleton_method(:analyze) { |_prompt, **_opts| raise "API error" }
    service = TicketDraftService.new(claude_service: mock_claude)
    original_new = TicketDraftService.method(:new)
    TicketDraftService.define_singleton_method(:new) { |**_| service }

    TicketDraftJob.perform_now(@topic.id)

    assert_not @topic.reload.drafting?
    assert_equal "open", @topic.status
  ensure
    TicketDraftService.define_singleton_method(:new, original_new)
  end
end
