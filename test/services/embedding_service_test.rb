require "test_helper"

class EmbeddingServiceTest < ActiveSupport::TestCase
  test "embed returns 1536-dim vector" do
    mock_response = { "data" => [{ "embedding" => Array.new(1536, 0.1), "index" => 0 }] }
    mock_client = Object.new
    mock_client.define_singleton_method(:embeddings) { |**| mock_response }

    result = EmbeddingService.new(client: mock_client).embed("hello")
    assert_equal 1536, result.length
  end

  test "embed_batch returns vectors in order" do
    mock_response = {
      "data" => [
        { "embedding" => Array.new(1536, 0.2), "index" => 1 },
        { "embedding" => Array.new(1536, 0.1), "index" => 0 }
      ]
    }
    mock_client = Object.new
    mock_client.define_singleton_method(:embeddings) { |**| mock_response }

    results = EmbeddingService.new(client: mock_client).embed_batch(["a", "b"])
    assert_equal 2, results.length
    assert_equal 0.1, results[0][0]
    assert_equal 0.2, results[1][0]
  end
end
