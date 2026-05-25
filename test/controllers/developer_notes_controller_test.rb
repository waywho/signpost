require "test_helper"

class DeveloperNotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @developer = create(:developer)
  end

  test "should create note" do
    assert_difference("DeveloperNote.count") do
      post developer_developer_notes_path(@developer),
        params: { developer_note: { content: "New observation", note_type: "good" } }
    end
    assert_redirected_to developer_path(@developer)
  end

  test "should create note via turbo_stream" do
    assert_difference("DeveloperNote.count") do
      post developer_developer_notes_path(@developer),
        params: { developer_note: { content: "New observation", note_type: "good" } },
        as: :turbo_stream
    end
    assert_response :success
  end

  test "should not create note with blank content" do
    assert_no_difference("DeveloperNote.count") do
      post developer_developer_notes_path(@developer),
        params: { developer_note: { content: "", note_type: "good" } }
    end
  end
end
