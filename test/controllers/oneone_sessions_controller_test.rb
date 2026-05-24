require "test_helper"

class OneoneSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @developer = developers(:one)
    @session = oneone_sessions(:one)
  end

  test "should get new" do
    get new_developer_oneone_session_path(@developer)
    assert_response :success
  end

  test "should create session" do
    assert_difference("OneoneSession.count") do
      post developer_oneone_sessions_path(@developer),
        params: { oneone_session: { session_date: Date.today, discussed: "Sprint review" } }
    end
    assert_redirected_to developer_oneone_session_path(@developer, OneoneSession.last)
  end

  test "should not create session without date" do
    assert_no_difference("OneoneSession.count") do
      post developer_oneone_sessions_path(@developer),
        params: { oneone_session: { session_date: "", discussed: "Sprint review" } }
    end
    assert_response :unprocessable_entity
  end

  test "should get show" do
    get developer_oneone_session_path(@developer, @session)
    assert_response :success
  end
end
