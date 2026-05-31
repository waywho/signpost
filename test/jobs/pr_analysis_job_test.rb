require "test_helper"

class PrAnalysisJobTest < ActiveJob::TestCase
  setup do
    @repo = "org/repo"
    @pr_number = 42
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "sets running cache key on start and clears on completion" do
    running_key = "pr_analysis_running:#{@repo}:#{@pr_number}"
    was_running = false

    original_analyze = PrAnalysisService.instance_method(:analyze)
    PrAnalysisService.define_method(:analyze) do |repo:, pr_number:, **|
      was_running = Rails.cache.exist?(running_key)
      { summary: "test", recommendation: "approve", risk_areas: [] }
    end

    original_cc = PrAnalysisService.instance_method(:claude_code_command)
    PrAnalysisService.define_method(:claude_code_command) { |*_| "claude -p test" }

    PrAnalysisJob.perform_now(repo: @repo, pr_number: @pr_number)

    assert was_running, "running key should be set during execution"
    refute Rails.cache.exist?(running_key), "running key should be cleared after completion"
  ensure
    PrAnalysisService.define_method(:analyze, original_analyze)
    PrAnalysisService.define_method(:claude_code_command, original_cc)
  end

  test "clears running cache key on failure" do
    running_key = "pr_analysis_running:#{@repo}:#{@pr_number}"

    original_analyze = PrAnalysisService.instance_method(:analyze)
    PrAnalysisService.define_method(:analyze) { |**_| raise "boom" }

    PrAnalysisJob.perform_now(repo: @repo, pr_number: @pr_number)

    refute Rails.cache.exist?(running_key), "running key should be cleared after failure"
  ensure
    PrAnalysisService.define_method(:analyze, original_analyze)
  end
end
