class PrAnalysisJob < ApplicationJob
  queue_as :default

  def perform(repo:, pr_number:)
    @repo = repo
    @pr_number = pr_number
    @stream_name = "pr_analysis:#{repo}:#{pr_number}"

    Rails.cache.write("pr_analysis_running:#{repo}:#{pr_number}", true, expires_in: 10.minutes)
    broadcast_status("Starting analysis...")

    service = PrAnalysisService.new
    result = service.analyze(repo:, pr_number:)

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

  def broadcast_complete(result, cc_command)
    Turbo::StreamsChannel.broadcast_replace_to(
      @stream_name,
      target: "pr_analysis_container",
      partial: "pr_reviews/analysis",
      locals: { analysis: result, cc_command:, repo: @repo, pr_number: @pr_number }
    )
  end

  def broadcast_error(message)
    Turbo::StreamsChannel.broadcast_replace_to(
      @stream_name,
      target: "pr_analysis_container",
      html: <<~HTML
        <div class="alert alert--negative">
          <p class="text-sm"><i class="ph ph-warning"></i> Analysis failed: #{ERB::Util.html_escape(message)}</p>
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
