class AddSummarySectionsToSlackThreads < ActiveRecord::Migration[8.1]
  def change
    add_column :slack_threads, :summary_sections, :jsonb, default: [], null: false
  end
end
