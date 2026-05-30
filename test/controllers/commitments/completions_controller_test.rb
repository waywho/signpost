require "test_helper"

class Commitments::CompletionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @commitment = create(:commitment)
  end

  test "create marks commitment done" do
    post commitment_completion_path(@commitment)
    assert_redirected_to commitments_path
    assert @commitment.reload.done
    assert_not_nil @commitment.done_at
  end

  test "create via turbo_stream" do
    post commitment_completion_path(@commitment), as: :turbo_stream
    assert_response :success
    assert @commitment.reload.done
  end
end
