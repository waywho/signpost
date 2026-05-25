class TicketDraftService
  def initialize(claude_service: nil)
    @claude = claude_service || ClaudeService.new
  end

  def draft(topic)
    thread = topic.slack_thread
    messages = thread.slack_messages.chronological
    message_text = messages.map { |m| "[#{m.user_name || 'Unknown'}] #{m.content}" }.join("\n")

    prompt = <<~PROMPT
      You are helping a tech lead create a GitHub issue from a Slack discussion.

      Thread: #{thread.title}
      Channel: #{thread.slack_channel_name}
      Topic: #{topic.title}
      Topic summary: #{topic.summary}
      Category: #{topic.category}
      Urgency: #{topic.urgency}

      Slack messages:
      #{message_text.truncate(3000)}

      Generate a GitHub issue. Return JSON:
      {
        "title": "concise issue title",
        "body": "markdown body with:\\n## Context\\n(what happened)\\n\\n## Problem\\n(what's wrong)\\n\\n## Expected Behavior\\n(what should happen)\\n\\n## Acceptance Criteria\\n- [ ] criterion 1\\n- [ ] criterion 2",
        "suggested_repo": "best guess repo name based on context, or null"
      }
    PROMPT

    response = @claude.analyze(prompt, max_tokens: 1500)
    JSON.parse(response.to_s.gsub(/```json|```/, "").strip).deep_symbolize_keys
  rescue JSON::ParserError
    { title: topic.title, body: topic.summary, suggested_repo: nil }
  end
end
