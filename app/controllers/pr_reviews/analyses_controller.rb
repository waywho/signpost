class PrReviews::AnalysesController < ApplicationController
  include ActionController::Live

  # run_analysis — SSE streaming endpoint (kept for evaluation)
  def show
    repo = params[:repo]
    pr_number = params[:pr_number].to_i
    pr_title = params[:pr_title]

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    github = GitHubService.new
    stream = response.stream

    begin
      pr = github.pr_detail(repo, pr_number)
      head_sha = pr[:head_sha]
      cache_key = "pr_analysis/#{repo}/#{pr_number}/#{head_sha}"
      cached = Rails.cache.read(cache_key)

      if cached
        send_sse(stream, type: "status", text: "Using cached analysis...")
        send_sse(stream, type: "complete", html: render_analysis_html(cached, repo, pr_number, pr_title))
      else
        send_sse(stream, type: "status", text: "Fetching PR diff from GitHub...")

        diff = github.pr_diff(repo, pr_number)
        comments = github.pr_comments(repo, pr_number)
        linked_issue = github.linked_issue(repo, pr_number)

        send_sse(stream, type: "status", text: "Running Claude analysis...")

        truncated_diff = diff.lines.first(4000).join
        service = PrAnalysisService.new(github_service: github)
        prompt = service.send(:build_prompt, pr, truncated_diff, comments, linked_issue)

        raw_output = ""
        require "open3"

        backend = Setting.get("global", "ai_backend", default: "cli")
        if backend == "cli"
          Open3.popen3("claude", "-p", "-", "--output-format", "text", "--max-turns", "3") do |stdin, stdout, stderr, wait_thr|
            stdin.write(prompt)
            stdin.close

            stdout.each_line do |line|
              raw_output << line
              send_sse(stream, type: "chunk", text: line)
            end
          end
        else
          raw_output = ClaudeService.new.analyze(prompt, max_tokens: 4000)
          send_sse(stream, type: "chunk", text: raw_output)
        end

        send_sse(stream, type: "status", text: "Parsing results...")

        result = service.send(:parse_response, raw_output)
        Rails.cache.write(cache_key, result)
        service.send(:save_to_pr_review, repo, pr_number, pr, head_sha, result)

        cc_command = service.claude_code_command(
          OpenStruct.new(pr_number:, pr_title:, repo:),
          (result[:risk_areas] || []).map { |r| r[:file] }.compact
        )

        send_sse(stream, type: "complete", html: render_analysis_html(result, repo, pr_number, pr_title, cc_command))
      end
    rescue => e
      send_sse(stream, type: "error", text: e.message)
    ensure
      stream.close
    end
  end

  def create
    @pr_review = PrReview.find(params[:pr_review_id])
    PrAnalysisJob.perform_later(repo: @pr_review.repo, pr_number: @pr_review.pr_number)
    redirect_to @pr_review, notice: "Re-analysis started."
  end

  private

  def send_sse(stream, **data)
    stream.write("data: #{data.to_json}\n\n")
  end

  def render_analysis_html(analysis, repo, pr_number, pr_title, cc_command = nil)
    cc_command ||= PrAnalysisService.new.claude_code_command(
      OpenStruct.new(pr_number:, pr_title:, repo:),
      (analysis[:risk_areas] || []).map { |r| r[:file] }.compact
    )
    render_to_string(partial: "pr_reviews/analysis", locals: { analysis:, cc_command:, repo:, pr_number: })
  end
end
