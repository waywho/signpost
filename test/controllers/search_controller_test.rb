require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  test "index renders search page" do
    get search_path
    assert_response :success
    assert_select "h1", "Semantic Search"
  end

  test "index with query renders results" do
    mock_service = Object.new
    mock_service.define_singleton_method(:search) { |**_kwargs| [] }
    original_new = SlackSearchService.method(:new)
    SlackSearchService.define_singleton_method(:new) { |**_kwargs| mock_service }

    get search_path, params: { query: "test" }

    SlackSearchService.define_singleton_method(:new, original_new)

    assert_response :success
  end

  test "returns error without query" do
    post search_path, params: {}, as: :json
    assert_response :unprocessable_entity
  end

  test "returns results with query" do
    original_new = SlackSearchService.method(:new)
    mock_service = Object.new
    mock_service.define_singleton_method(:search) { |**_kwargs| [] }

    SlackSearchService.define_singleton_method(:new) { |**_kwargs| mock_service }

    post search_path, params: { query: "test" }, as: :json

    SlackSearchService.define_singleton_method(:new, original_new)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "test", body["query"]
    assert_kind_of Array, body["results"]
    assert_equal 0, body["count"]
  end
end
