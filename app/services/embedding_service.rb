class EmbeddingService
  MODEL = "text-embedding-3-small"

  def initialize(client: nil)
    @client = client || OpenAI::Client.new
  end

  def embed(text)
    response = @client.embeddings(parameters: { model: MODEL, input: text })
    response.dig("data", 0, "embedding")
  end

  def embed_batch(texts)
    response = @client.embeddings(parameters: { model: MODEL, input: texts })
    response["data"].sort_by { |d| d["index"] }.map { |d| d["embedding"] }
  end
end
