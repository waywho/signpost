class AddAnalysisAndDeveloperToPrReviews < ActiveRecord::Migration[8.1]
  def change
    add_reference :pr_reviews, :developer, foreign_key: true, type: :uuid, null: true
    add_column :pr_reviews, :head_sha, :text
  end
end
