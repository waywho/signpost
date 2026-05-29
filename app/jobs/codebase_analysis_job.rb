class CodebaseAnalysisJob < ApplicationJob
  queue_as :default

  def perform(codebase_analysis_id)
    analysis = CodebaseAnalysis.find(codebase_analysis_id)
    CodebaseAnalysisService.new.analyze(analysis)
  end
end
