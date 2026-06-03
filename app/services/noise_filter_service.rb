class NoiseFilterService
  def initialize(client: nil)
    @client = client || Anthropic::Client.new(api_key: EncryptedSetting.get("credentials", "anthropic_api_key"))
  end

  def noise?(message_content)
    filters = NoiseFilter.enabled.pluck(:category, :description)
    return false if filters.empty?

    filter_list = filters.map { |cat, desc| "- #{cat}: #{desc}" }.join("\n")

    response = @client.messages(
      parameters: {
        model: "claude-haiku-4-5-20251001",
        max_tokens: 10,
        messages: [ { role: "user", content: <<~PROMPT } ]
          Classify this Slack message. Is it noise that should be skipped?

          Noise categories:
          #{filter_list}

          Message: "#{message_content}"

          Reply with exactly "NOISE" or "KEEP". Nothing else.
        PROMPT
      }
    )

    response.dig("content", 0, "text")&.strip&.upcase == "NOISE"
  rescue => e
    Rails.logger.error("NoiseFilterService error: #{e.message}")
    false
  end
end
