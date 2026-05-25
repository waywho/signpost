require "test_helper"

class CommitmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @commitment = create(:commitment)
  end

  test "should get index" do
    get commitments_path
    assert_response :success
  end

  test "should get new" do
    get new_commitment_path
    assert_response :success
  end

  test "should create commitment" do
    assert_difference("Commitment.count") do
      post commitments_path, params: { commitment: { text: "New commitment", stakeholder: "PM" } }
    end
    assert_redirected_to commitments_path
  end

  test "should not create without text" do
    assert_no_difference("Commitment.count") do
      post commitments_path, params: { commitment: { text: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "should mark done" do
    patch done_commitment_path(@commitment)
    assert_redirected_to commitments_path
    assert @commitment.reload.done
    assert_not_nil @commitment.done_at
  end

  test "should mark done via turbo_stream" do
    patch done_commitment_path(@commitment), as: :turbo_stream
    assert_response :success
    assert @commitment.reload.done
  end

  test "should destroy" do
    assert_difference("Commitment.count", -1) do
      delete commitment_path(@commitment)
    end
    assert_redirected_to commitments_path
  end
end
