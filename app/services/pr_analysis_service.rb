class PrAnalysisService
  STACK = "Ruby on Rails 8, Stimulus JS, css-zero, ViewComponent, PostgreSQL"

  def initialize(github_service: nil, claude_service: nil)
    @github = github_service || GitHubService.new
    @claude = claude_service || ClaudeService.new
  end

  def analyze(repo:, pr_number:, force: false)
    pr = @github.pr_detail(repo, pr_number)
    head_sha = pr[:head_sha]
    cache_key = "pr_analysis/#{repo}/#{pr_number}/#{head_sha}"

    unless force
      cached = Rails.cache.read(cache_key)
      return cached if cached
    end

    diff = @github.pr_diff(repo, pr_number)
    comments = @github.pr_comments(repo, pr_number)
    linked_issue = @github.linked_issue(repo, pr_number)
    truncated_diff = diff.lines.first(4000).join
    prompt = build_prompt(pr, truncated_diff, comments, linked_issue)
    response = @claude.analyze(prompt, max_tokens: 4000)
    result = parse_response(response)

    Rails.cache.write(cache_key, result, expires_in: 7.days)
    save_to_pr_review(repo, pr_number, pr, head_sha, result)
    result
  end

  def claude_code_command(pr_review, risk_files)
    risk_list = risk_files.join(", ")
    <<~CMD
      claude -p "Review this PR against our codebase and CLAUDE.md conventions.

      PR: ##{pr_review.pr_number} — #{pr_review.pr_title}
      Repo: #{pr_review.repo}

      Pre-analysis identified these risk areas: #{risk_list}

      Please:
      1. Read CLAUDE.md for our conventions
      2. Look at the risk files: #{risk_list}
      3. Check for N+1 queries, missing indexes, Rails anti-patterns
      4. Check ViewComponent usage follows our patterns
      5. Check Stimulus controllers for lifecycle issues
      6. Verify CSS follows our design system
      7. Flag anything that conflicts with our conventions
      8. Give a final recommendation: approve / request changes / discuss

      Be specific about file:line references."
    CMD
  end

  private

  def build_prompt(pr, diff, comments, linked_issue)
    issue_context = linked_issue ? "Linked issue ##{linked_issue[:number]}: #{linked_issue[:title]}\n#{linked_issue[:body]}" : "No linked issue found"
    comment_context = comments.any? ? comments.map { |c| "#{c[:user]}: #{c[:body]}" }.join("\n") : "None"

    <<~PROMPT
      You are an expert code reviewer helping a tech lead review a pull request. The stack is: #{STACK}.

      Review using this structured methodology:
      1. Plan alignment — does the PR match its linked issue/description? Are deviations justified?
      2. Code quality — separation of concerns, error handling, DRY without premature abstraction, edge cases
      3. Architecture — sound design decisions, scalability, security, clean integration
      4. Testing — tests verify real behavior (not mocks), edge cases covered, integration tests where they matter
      5. Production readiness — migration strategy, backward compatibility, no obvious bugs

      PR: ##{pr[:number]} — #{pr[:title]}
      Author: #{pr[:author]}
      Description: #{pr[:body] || "No description"}
      Changed files: #{pr[:changed_files]}, Additions: #{pr[:additions]}, Deletions: #{pr[:deletions]}

      Linked issue:
      #{issue_context}

      Previous review comments:
      #{comment_context}

      Diff (truncated to 4000 lines):
      #{diff}

      Return ONLY valid JSON:
      {
        "recommendation": "APPROVE|REQUEST_CHANGES|NEEDS_DISCUSSION",
        "recommendation_reason": "one clear sentence",
        "summary": "2-3 sentence summary of what this PR does",
        "critical_flags": [{"severity": "critical|warning", "title": "...", "detail": "..."}],
        "strengths": ["what's well done — specific file:line references"],
        "issues": {
          "critical": [{"file": "path", "line": "range", "issue": "what's wrong", "why": "why it matters", "fix": "how to fix"}],
          "important": [{"file": "path", "line": "range", "issue": "...", "why": "...", "fix": "..."}],
          "minor": [{"file": "path", "line": "range", "issue": "...", "why": "...", "fix": "..."}]
        },
        "solves_ticket": {"result": "yes|no|unclear", "explanation": "..."},
        "risk_areas": [{"file": "filename", "severity": "high|medium|low", "reason": "specific concern"}],
        "missing_tests": ["specific untested scenario"],
        "performance_concerns": ["concern"],
        "security_issues": ["issue"],
        "before_review_tips": ["what to focus on, tailored to PR type and stack"],
        "inline_tips": [{"file": "filename", "tip": "what to look for", "why": "educational reason"}],
        "after_checklist": [{"item": "checklist item", "why": "why this matters for this stack/change"}],
        "draft_comment": "ready-to-post review comment — constructive, specific, references actual code"
      }

      WRITING STYLE — be terse like a senior reviewer:
      - Every string value: one sentence max. No filler, no hedging, no "I noticed that..."
      - Issues: "file:line: problem. fix." — not paragraphs
      - Strengths: "Clean error handling in auth_controller.rb:45-60" — not "The error handling is well done"
      - Tips: "Check N+1 on user.posts" — not "You might want to consider checking for N+1 queries"
      - Draft comment: direct, actionable, references specific lines. No "Overall looks good but..."
      - Use 🔴 🟡 🔵 prefixes in issue descriptions for visual scanning

      Categorize issues by actual severity. Not everything is Critical.
      Acknowledge what was done well before listing issues.
      Be specific with file:line references.
    PROMPT
  end

  def parse_response(response)
    json_text = response.to_s.gsub(/```json|```/, "").strip
    JSON.parse(json_text).deep_symbolize_keys
  rescue JSON::ParserError
    { summary: response.to_s.truncate(500), parse_error: true }
  end

  def save_to_pr_review(repo, pr_number, pr, head_sha, result)
    return if result[:parse_error]

    developer = Developer.find_by("LOWER(github_handle) = ?", pr[:author]&.downcase)
    issues = result[:issues] || {}
    issue_counts = {
      critical: (issues[:critical] || []).size,
      important: (issues[:important] || []).size,
      minor: (issues[:minor] || []).size
    }

    # One-line competence summary for developer tracking
    competence_summary = build_competence_summary(result, issue_counts)

    PrReview.create!(
      repo: repo,
      pr_number: pr_number,
      pr_title: pr[:title],
      pr_author: pr[:author],
      recommendation: result[:recommendation],
      risk_level: result.dig(:risk_areas, 0, :severity)&.upcase,
      summary: competence_summary,
      head_sha: head_sha,
      developer: developer,
      reviewed_at: Time.current,
      additions: pr[:additions],
      deletions: pr[:deletions],
      files_changed: pr[:changed_files]
    )
  rescue => e
    Rails.logger.error("PrAnalysisService save_to_pr_review error: #{e.message}")
  end

  def build_competence_summary(result, counts)
    parts = []
    parts << result[:recommendation]&.downcase&.tr("_", " ")
    parts << "#{counts[:critical]}🔴 #{counts[:important]}🟡 #{counts[:minor]}🔵"
    strengths = result[:strengths]
    parts << "Strengths: #{strengths.first}" if strengths&.any?
    top_issue = (result.dig(:issues, :critical) || result.dig(:issues, :important))&.first
    parts << "Top issue: #{top_issue[:issue]}" if top_issue
    parts.compact.join(". ")
  end
end
