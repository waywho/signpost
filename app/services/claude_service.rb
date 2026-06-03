class ClaudeService
  BACKENDS = %w[api cli].freeze

  def initialize(client: nil)
    @explicit_client = client
  end

  def configured?
    case backend
    when "cli"
      system("which claude > /dev/null 2>&1")
    when "api"
      EncryptedSetting.get("credentials", "anthropic_api_key").present?
    else
      false
    end
  end

  def analyze(prompt, max_tokens: 4000, model: "claude-sonnet-4-20250514")
    case backend
    when "cli"
      analyze_via_cli(prompt, max_tokens: max_tokens, model: model)
    when "api"
      analyze_via_api(prompt, max_tokens: max_tokens, model: model)
    else
      raise "Unknown AI backend: #{backend}. Set ai_backend to 'cli' or 'api' in settings."
    end
  end

  private

  def backend
    @explicit_client ? "api" : Setting.get("global", "ai_backend", default: "cli")
  end

  def analyze_via_api(prompt, max_tokens:, model:)
    client = @explicit_client || Anthropic::Client.new(api_key: EncryptedSetting.get("credentials", "anthropic_api_key"))
    response = client.messages(
      parameters: {
        model: model,
        max_tokens: max_tokens,
        messages: [ { role: "user", content: prompt } ]
      }
    )
    response.dig("content", 0, "text")
  end

  def analyze_via_cli(prompt, max_tokens:, model:)
    require "open3"

    stdout, stderr, status = Open3.capture3("claude", "-p", "-", "--output-format", "text", "--max-turns", "1", stdin_data: prompt)

    unless status.success?
      error = stderr.presence || stdout
      Rails.logger.error("Claude CLI failed: #{error}")
      raise "Claude CLI failed: #{error.truncate(200)}"
    end

    stdout.strip
  end
end
