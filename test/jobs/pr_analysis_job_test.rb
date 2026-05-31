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

    original_prepare = PrAnalysisService.instance_method(:prepare)
    PrAnalysisService.define_method(:prepare) do |repo:, pr_number:|
      was_running = Rails.cache.exist?(running_key)
      { cached: true, result: { summary: "test", recommendation: "approve", risk_areas: [] },
        pr: { title: "Fix" }, head_sha: "abc", cache_key: "test" }
    end

    original_cc = PrAnalysisService.instance_method(:claude_code_command)
    PrAnalysisService.define_method(:claude_code_command) { |*_| "claude -p test" }

    PrAnalysisJob.perform_now(repo: @repo, pr_number: @pr_number)

    assert was_running, "running key should be set during execution"
    refute Rails.cache.exist?(running_key), "running key should be cleared after completion"
  ensure
    PrAnalysisService.define_method(:prepare, original_prepare)
    PrAnalysisService.define_method(:claude_code_command, original_cc)
  end

  test "clears running cache key on failure" do
    running_key = "pr_analysis_running:#{@repo}:#{@pr_number}"

    original_prepare = PrAnalysisService.instance_method(:prepare)
    PrAnalysisService.define_method(:prepare) { |**_| raise "boom" }

    PrAnalysisJob.perform_now(repo: @repo, pr_number: @pr_number)

    refute Rails.cache.exist?(running_key), "running key should be cleared after failure"
  ensure
    PrAnalysisService.define_method(:prepare, original_prepare)
  end

  test "uses cached result without streaming" do
    original_prepare = PrAnalysisService.instance_method(:prepare)
    PrAnalysisService.define_method(:prepare) do |repo:, pr_number:|
      { cached: true, result: { summary: "cached", recommendation: "approve", risk_areas: [] },
        pr: { title: "Fix" }, head_sha: "abc", cache_key: "test" }
    end

    original_cc = PrAnalysisService.instance_method(:claude_code_command)
    PrAnalysisService.define_method(:claude_code_command) { |*_| "claude -p test" }

    PrAnalysisJob.perform_now(repo: @repo, pr_number: @pr_number)
    refute Rails.cache.exist?("pr_analysis_running:#{@repo}:#{@pr_number}"), "running key should be cleared"
  ensure
    PrAnalysisService.define_method(:prepare, original_prepare)
    PrAnalysisService.define_method(:claude_code_command, original_cc)
  end
end
