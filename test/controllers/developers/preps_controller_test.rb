require "test_helper"

class Developers::PrepsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @developer = create(:developer)
  end

  test "create runs prep and returns turbo_stream" do
    mock = Object.new
    mock.define_singleton_method(:prep) { |_dev| "Briefing content" }
    original_new = OneOnePrepService.method(:new)
    OneOnePrepService.define_singleton_method(:new) { |**_| mock }

    post developer_prep_path(@developer), as: :turbo_stream
    assert_response :success
  ensure
    OneOnePrepService.define_singleton_method(:new, original_new)
  end
end
