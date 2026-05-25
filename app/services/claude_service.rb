class ClaudeService
  def initialize(client: nil)
    @client = client || Anthropic::Client.new(api_key: EncryptedSetting.get("credentials", "anthropic_api_key"))
  end

  def configured?
    EncryptedSetting.get("credentials", "anthropic_api_key").present?
  end

  def analyze(prompt, max_tokens: 4000, model: "claude-sonnet-4-20250514")
    response = @client.messages(
      parameters: {
        model: model,
        max_tokens: max_tokens,
        messages: [{ role: "user", content: prompt }]
      }
    )
    response.dig("content", 0, "text")
  end
end
