require "test_helper"

class DevelopersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @developer = create(:developer)
  end

  test "should get index" do
    get developers_path
    assert_response :success
  end

  test "should get show" do
    get developer_path(@developer)
    assert_response :success
    assert_select "h1", @developer.name
  end

  test "should get new" do
    get new_developer_path
    assert_response :success
  end

  test "should create developer" do
    assert_difference("Developer.count") do
      post developers_path, params: { developer: { name: "Charlie", level: "Junior" } }
    end
    assert_redirected_to developer_path(Developer.last)
  end

  test "should not create invalid developer" do
    assert_no_difference("Developer.count") do
      post developers_path, params: { developer: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_developer_path(@developer)
    assert_response :success
  end

  test "should update developer" do
    patch developer_path(@developer), params: { developer: { name: "Updated" } }
    assert_redirected_to developer_path(@developer)
    assert_equal "Updated", @developer.reload.name
  end

  test "should destroy developer" do
    assert_difference("Developer.count", -1) do
      delete developer_path(@developer)
    end
    assert_redirected_to developers_path
  end
end
