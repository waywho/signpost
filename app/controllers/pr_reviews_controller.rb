class PrReviewsController < ApplicationController
  include ActionController::Live

  def index
    @pr_queue = begin
      service = GitHubService.new
      service.configured? ? service.pr_queue : nil
    rescue => e
      Rails.logger.error("PR queue fetch failed: #{e.message}")
      nil
    end

    @claude_configured = ClaudeService.new.configured?
    if @pr_queue&.any?
      pr_keys = @pr_queue.map { |pr| [pr[:repo], pr[:number]] }
      @analyzed_prs = PrReview.where(repo: pr_keys.map(&:first), pr_number: pr_keys.map(&:last))
                              .pluck(:repo, :pr_number).to_set
    else
      @analyzed_prs = Set.new
    end

    @pr_reviews = PrReview.recent
    @pr_reviews = @pr_reviews.where(repo: params[:repo]) if params[:repo].present?
    @pr_reviews = @pr_reviews.where(recommendation: params[:recommendation]) if params[:recommendation].present?
    @pr_reviews = @pr_reviews.where(risk_level: params[:risk_level]) if params[:risk_level].present?
  end

  def show
    @pr_review = PrReview.find(params[:id])
    @claude_configured = ClaudeService.new.configured?
    @github_configured = GitHubService.new.configured?
  end

  def ignore
    urls = Array(params[:urls].presence || params[:url])
    ignored = Setting.get("global", "ignored_prs", default: []) || []
    urls.each { |url| ignored << url unless ignored.include?(url) }
    Setting.set("global", "ignored_prs", ignored)
    count = urls.size
    redirect_back fallback_location: pr_reviews_path, notice: "#{count} PR#{'s' if count > 1} ignored."
  end

  def analyze_pr
    @repo = params[:repo]
    @pr_number = params[:pr_number].to_i
    @pr_title = params[:pr_title]
    @pr_author = params[:pr_author]
  end

  def run_analysis
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
          Open3.popen3("claude", "-p", "-", "--output-format", "text", "--max-turns", "1") do |stdin, stdout, stderr, wait_thr|
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
        Rails.cache.write(cache_key, result, expires_in: 7.days)
        service.send(:save_to_pr_review, repo, pr_number, pr, head_sha, result)

        cc_command = service.claude_code_command(
          OpenStruct.new(pr_number: pr_number, pr_title: pr_title, repo: repo),
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

  def analyze
    @pr_review = PrReview.find(params[:id])
    service = PrAnalysisService.new
    @analysis = service.analyze(repo: @pr_review.repo, pr_number: @pr_review.pr_number)
    @cc_command = service.claude_code_command(
      @pr_review,
      (@analysis[:risk_areas] || []).map { |r| r[:file] }.compact
    )
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @pr_review }
    end
  rescue => e
    @error = e.message
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @pr_review, alert: "Analysis failed: #{e.message}" }
    end
  end

  private

  def send_sse(stream, **data)
    stream.write("data: #{data.to_json}\n\n")
  end

  def render_analysis_html(analysis, repo, pr_number, pr_title, cc_command = nil)
    cc_command ||= PrAnalysisService.new.claude_code_command(
      OpenStruct.new(pr_number: pr_number, pr_title: pr_title, repo: repo),
      (analysis[:risk_areas] || []).map { |r| r[:file] }.compact
    )
    render_to_string(partial: "pr_reviews/analysis", locals: { analysis: analysis, cc_command: cc_command })
  end
end
