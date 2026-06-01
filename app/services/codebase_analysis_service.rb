class CodebaseAnalysisService
  def analyze(codebase_analysis)
    codebase_analysis.update!(status: :running, started_at: Time.current)

    prompt = build_prompt(codebase_analysis)
    codebase_analysis.update!(prompt_context: prompt)

    output = run_claude(prompt, directory: codebase_analysis.repo_path)
    parsed = extract_draft(output)

    codebase_analysis.update!(
      status: :completed,
      analysis: output,
      draft_title: parsed[:title],
      draft_body: parsed[:body],
      completed_at: Time.current
    )
  rescue => e
    codebase_analysis.update!(
      status: :failed,
      error_message: e.message,
      completed_at: Time.current
    )
  end

  private

  def build_prompt(codebase_analysis)
    thread = codebase_analysis.slack_thread
    messages = thread.slack_messages.chronological
    message_text = messages.map { |m| "[#{m.user_name || 'Unknown'}] #{m.content}" }.join("\n")

    <<~PROMPT
      You are a senior engineer investigating a bug/issue reported in a Slack thread.

      ## Thread Context
      Title: #{thread.title}
      Channel: #{thread.slack_channel_name}
      Summary: #{thread.summary}
      Keywords: #{thread.keywords&.join(', ')}

      ## Slack Messages
      #{message_text.truncate(4000)}

      ## Topics
      #{thread.slack_topics.map { |t| "- #{t.title} (#{t.urgency}): #{t.summary}" }.join("\n")}

      ## Instructions
      1. Investigate the codebase to understand the issue described above.
      2. Find relevant files, functions, and code paths.
      3. Produce a structured analysis.

      Return your response in this format:

      ## Analysis
      (Your investigation findings — what you found in the code, root cause hypothesis, affected files/functions)

      ## Draft Issue
      TITLE: (concise issue title)
      BODY:
      (markdown issue body with Context, Problem, Root Cause, Suggested Fix, Acceptance Criteria)
    PROMPT
  end

  def run_claude(prompt, directory:)
    require "open3"
    stdout, stderr, status = Open3.capture3(
      "claude", "-p", "-",
      "--output-format", "text", "--max-turns", "10",
      stdin_data: prompt, chdir: directory
    )
    raise "Claude CLI failed: #{(stderr.presence || stdout).truncate(500)}" unless status.success?
    stdout.strip
  end

  def extract_draft(output)
    title = output[/^TITLE:\s*(.+)$/i, 1]&.strip
    body_match = output.match(/^BODY:\s*\n(.*)/mi)
    body = body_match ? body_match[1].strip : nil
    { title: title || "Untitled", body: body || output }
  end
end
