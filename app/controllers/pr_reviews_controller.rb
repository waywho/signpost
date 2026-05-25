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

    @pr_reviews = PrReview.recent
    @pr_reviews = @pr_reviews.where(repo: params[:repo]) if params[:repo].present?
    @pr_reviews = @pr_reviews.where(recommendation: params[:recommendation]) if params[:recommendation].present?
    @pr_reviews = @pr_reviews.where(risk_level: params[:risk_level]) if params[:risk_level].present?
  end

  def show
    @pr_review = PrReview.find(params[:id])
  end

  def new
    @pr_review = PrReview.new(
      repo: params[:repo],
      pr_number: params[:pr_number],
      pr_title: params[:pr_title],
      pr_author: params[:pr_author],
      reviewed_at: Time.current
    )
  end

  def create
    @pr_review = PrReview.new(pr_review_params)
    if @pr_review.save
      redirect_to @pr_review, notice: "Review logged."
    else
      render :new, status: :unprocessable_entity
    end
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
    pr_author = params[:pr_author]

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    github = GitHubService.new
    sse = ActionController::Live::SSE.new(response.stream)

    begin
      # Check cache first
      pr = github.pr_detail(repo, pr_number)
      head_sha = pr[:head_sha]
      cache_key = "pr_analysis/#{repo}/#{pr_number}/#{head_sha}"
      cached = Rails.cache.read(cache_key)

      if cached
        sse.write({ type: "status", text: "Using cached analysis..." }.to_json)
        sse.write({ type: "complete", html: render_analysis_html(cached, repo, pr_number, pr_title) }.to_json)
      else
        sse.write({ type: "status", text: "Fetching PR diff from GitHub..." }.to_json)

        diff = github.pr_diff(repo, pr_number)
        comments = github.pr_comments(repo, pr_number)
        linked_issue = github.linked_issue(repo, pr_number)

        sse.write({ type: "status", text: "Running Claude analysis..." }.to_json)

        # Stream Claude output line by line
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
              sse.write({ type: "chunk", text: line }.to_json)
            end
          end
        else
          raw_output = ClaudeService.new.analyze(prompt, max_tokens: 4000)
          sse.write({ type: "chunk", text: raw_output }.to_json)
        end

        sse.write({ type: "status", text: "Parsing results..." }.to_json)

        result = service.send(:parse_response, raw_output)
        Rails.cache.write(cache_key, result, expires_in: 7.days)
        service.send(:save_to_pr_review, repo, pr_number, pr, head_sha, result)

        cc_command = service.claude_code_command(
          OpenStruct.new(pr_number: pr_number, pr_title: pr_title, repo: repo),
          (result[:risk_areas] || []).map { |r| r[:file] }.compact
        )

        sse.write({ type: "complete", html: render_analysis_html(result, repo, pr_number, pr_title, cc_command) }.to_json)
      end
    rescue => e
      sse.write({ type: "error", text: e.message }.to_json)
    ensure
      sse.close
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

  def pr_review_params
    params.require(:pr_review).permit(
      :pr_number, :repo, :pr_title, :pr_author,
      :recommendation, :risk_level, :summary, :draft_comment,
      :files_changed, :additions, :deletions, :reviewed_at
    )
  end

  def render_analysis_html(analysis, repo, pr_number, pr_title, cc_command = nil)
    cc_command ||= PrAnalysisService.new.claude_code_command(
      OpenStruct.new(pr_number: pr_number, pr_title: pr_title, repo: repo),
      (analysis[:risk_areas] || []).map { |r| r[:file] }.compact
    )
    render_to_string(partial: "pr_reviews/analysis", locals: { analysis: analysis, cc_command: cc_command })
  end
end
