require "test_helper"

class CodebaseAnalyses::DelegationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thread = create(:slack_thread, slack_channel_id: "C123", slack_thread_ts: "123.456")
    @analysis = create(:codebase_analysis, slack_thread: @thread, status: :completed,
      draft_title: "Fix OAuth bug", draft_body: "body")
  end

  test "create creates delegation and links to analysis" do
    developer = create(:developer, name: "Bob")
    assert_difference("Delegation.count") do
      post slack_thread_codebase_analysis_delegation_path(@thread, @analysis),
        params: { developer_id: developer.id }
    end
    assert_redirected_to slack_thread_path(@thread)
    assert @analysis.reload.delegation.present?
    assert_equal developer, @analysis.delegation.developer
  end
end
