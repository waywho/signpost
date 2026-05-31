class PrAnalysisJob < ApplicationJob
  queue_as :default

  def perform(repo:, pr_number:)
    @repo = repo
    @pr_number = pr_number
    @stream_name = "pr_analysis:#{repo}:#{pr_number}"

    Rails.cache.write("pr_analysis_running:#{repo}:#{pr_number}", true, expires_in: 10.minutes)
    broadcast_status("Starting analysis...")

    service = PrAnalysisService.new
    prepared = service.prepare(repo:, pr_number:)

    if prepared[:cached]
      result = prepared[:result]
    else
      broadcast_status("Fetching PR diff from GitHub...")
      broadcast_status("Running Claude analysis...")
      result = run_analysis(service, prepared)
    end

    cc_command = service.claude_code_command(
      OpenStruct.new(pr_number:, pr_title: result[:summary], repo:),
      (result[:risk_areas] || []).map { |r| r[:file] }.compact
    )

    broadcast_complete(result, cc_command)
    broadcast_row_update
  rescue => e
    Rails.logger.error("PrAnalysisJob failed for #{@repo}##{@pr_number}: #{e.message}")
    broadcast_error(e.message)
  ensure
    Rails.cache.delete("pr_analysis_running:#{@repo}:#{@pr_number}")
  end

  private

  def run_analysis(service, prepared)
    backend = Setting.get("global", "ai_backend", default: "cli")
    raw_output = ""

    if backend == "cli"
      require "open3"
      Open3.popen3("claude", "-p", "-", "--output-format", "text", "--max-turns", "3") do |stdin, stdout, _stderr, _wait_thr|
        stdin.write(prepared[:prompt])
        stdin.close

        stdout.each_line do |line|
          raw_output << line
          broadcast_chunk(line)
        end
      end
    else
      raw_output = ClaudeService.new.analyze(prepared[:prompt], max_tokens: 4000)
      broadcast_chunk(raw_output)
    end

    broadcast_status("Parsing results...")
    service.parse_and_save(
      raw_output,
      repo: @repo, pr_number: @pr_number,
      pr: prepared[:pr], head_sha: prepared[:head_sha], cache_key: prepared[:cache_key]
    )
  end

  def broadcast_status(text)
    Turbo::StreamsChannel.broadcast_update_to(
      @stream_name,
      target: "pr_analysis_status",
      html: <<~HTML
        <div class="card text-center p-4">
          <div style="font-size: var(--text-4xl); color: var(--color-primary); animation: spin 1s linear infinite; margin-block-end: var(--size-4)">
            <i class="ph ph-spinner"></i>
          </div>
          <p class="text-sm" style="color: var(--color-text-subtle)">#{ERB::Util.html_escape(text)}</p>
        </div>
      HTML
    )
  end

  def broadcast_chunk(text)
    Turbo::StreamsChannel.broadcast_append_to(
      @stream_name,
      target: "pr_analysis_stream",
      html: "<span>#{ERB::Util.html_escape(text)}</span>"
    )
  end

  def broadcast_complete(result, cc_command)
    analysis_html = ApplicationController.render(
      partial: "pr_reviews/analysis",
      locals: { analysis: result, cc_command:, repo: @repo, pr_number: @pr_number }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      @stream_name,
      target: "pr_analysis_container",
      html: "<div id=\"pr_analysis_container\">#{analysis_html}</div>"
    )
  end

  def broadcast_error(message)
    Turbo::StreamsChannel.broadcast_replace_to(
      @stream_name,
      target: "pr_analysis_container",
      html: <<~HTML
        <div id="pr_analysis_container">
          <div class="alert alert--negative">
            <p class="text-sm"><i class="ph ph-warning"></i> Analysis failed: #{ERB::Util.html_escape(message)}</p>
          </div>
        </div>
      HTML
    )
  end

  def broadcast_row_update
    actions_id = "pr_queue_actions_#{@repo.tr('/', '_')}_#{@pr_number}"
    Turbo::StreamsChannel.broadcast_replace_to(
      "pr_analysis_results",
      target: actions_id,
      html: <<~HTML
        <div id="#{actions_id}" class="flex items-center gap-half" style="flex-shrink: 0">
          <a href="/pr_reviews/analysis/new?repo=#{ERB::Util.url_encode(@repo)}&pr_number=#{@pr_number}"
             class="text-sm flex items-center gap-half" style="color: var(--color-positive)">
            <i class="ph ph-check-circle"></i> Analyzed
          </a>
        </div>
      HTML
    )
  end
end
