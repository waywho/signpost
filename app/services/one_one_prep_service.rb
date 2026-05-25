class OneOnePrepService
  def initialize(claude_service: nil, github_service: nil)
    @claude = claude_service || ClaudeService.new
    @github = github_service || GitHubService.new
  end

  def prep(developer)
    context = gather_context(developer)
    prompt = build_prompt(developer, context)
    @claude.analyze(prompt, max_tokens: 2000)
  end

  private

  def gather_context(developer)
    {
      notes: developer.developer_notes.where("created_at > ?", 3.months.ago).order(created_at: :desc).map { |n| { type: n.note_type, content: n.content, date: n.created_at.strftime("%b %-d") } },
      last_oneone: developer.oneone_sessions.recent.first,
      delegations: developer.delegations.active.map { |d| { summary: d.summary, status: d.status, urgency: d.urgency } },
      github_activity: fetch_activity(developer),
      profile: { strengths: developer.strengths, growth_areas: developer.growth_areas, career_goals: developer.career_goals }
    }
  end

  def fetch_activity(developer)
    return [] unless developer.github_handle.present? && @github.configured?
    @github.developer_activity(developer.github_handle, days: 30)
  rescue => e
    Rails.logger.error("OneOnePrepService GitHub activity error: #{e.message}")
    []
  end

  def build_prompt(developer, context)
    notes_text = context[:notes].map { |n| "[#{n[:date]}] #{n[:type]}: #{n[:content]}" }.join("\n")

    last_oneone_text = if context[:last_oneone]
      s = context[:last_oneone]
      "Date: #{s.session_date}\nDiscussed: #{s.discussed}\nWins: #{s.wins}\nChallenges: #{s.challenges}\nAction Items: #{s.action_items}"
    else
      "No previous 1:1 recorded"
    end

    delegations_text = context[:delegations].any? ?
      context[:delegations].map { |d| "- #{d[:summary]} (#{d[:status]}, #{d[:urgency]})" }.join("\n") :
      "No active delegations"

    activity_text = context[:github_activity].any? ?
      context[:github_activity].first(10).map { |a| "- #{a[:type]}: #{a[:title]} (#{a[:repo]})" }.join("\n") :
      "No recent GitHub activity"

    <<~PROMPT
      You are helping a tech lead prepare for a 1:1 meeting with #{developer.name} (#{developer.role}, #{developer.level}).

      Developer profile:
      Strengths: #{context[:profile][:strengths] || "Not recorded"}
      Growth areas: #{context[:profile][:growth_areas] || "Not recorded"}
      Career goals: #{context[:profile][:career_goals] || "Not recorded"}

      Recent observations (last 3 months):
      #{notes_text.presence || "No notes recorded"}

      Last 1:1 session:
      #{last_oneone_text}

      Active delegations:
      #{delegations_text}

      GitHub activity (last 30 days):
      #{activity_text}

      Generate a 1:1 prep briefing with these sections:

      ## Suggested Talking Points
      Based on recent notes and activity, what should you discuss?

      ## Follow-ups from Last 1:1
      Any open action items or topics that need revisiting?

      ## Concerns to Address
      Issues flagged in "concern" notes that need attention.

      ## Growth Opportunities
      Based on "growth" notes and career goals, what to encourage or suggest.

      ## Wins to Acknowledge
      Recent achievements from "good" notes and GitHub activity worth recognizing.

      Be specific and actionable. Reference actual notes and activity where possible.
    PROMPT
  end
end
