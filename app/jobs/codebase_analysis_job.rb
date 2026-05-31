class CodebaseAnalysisJob < ApplicationJob
  queue_as :default

  def perform(codebase_analysis_id)
    analysis = CodebaseAnalysis.find(codebase_analysis_id)
    CodebaseAnalysisService.new.analyze(analysis)
    analysis.reload
    broadcast_result(analysis)
  end

  private

  def broadcast_result(analysis)
    developers = Developer.by_name
    github_repos = Setting.get("global", "github_repos", default: []) || []

    Turbo::StreamsChannel.broadcast_replace_to(
      analysis,
      target: "codebase_analysis_#{analysis.id}",
      partial: "codebase_analyses/analysis_card",
      locals: { analysis:, developers:, github_repos: }
    )
  end
end
