class CreatePrReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :pr_reviews, id: :uuid do |t|
      t.integer :pr_number, null: false
      t.text :repo, null: false
      t.text :pr_title
      t.text :pr_author
      t.text :recommendation
      t.text :risk_level
      t.text :summary
      t.jsonb :critical_flags, default: []
      t.jsonb :risk_areas, default: []
      t.jsonb :missing_tests, default: []
      t.jsonb :business_logic_risk, default: {}
      t.jsonb :ddd_issues, default: []
      t.jsonb :oop_issues, default: []
      t.text :draft_comment
      t.integer :files_changed
      t.integer :additions
      t.integer :deletions
      t.timestamptz :reviewed_at, default: -> { "NOW()" }
      t.timestamps
    end

    add_index :pr_reviews, :repo
    add_check_constraint :pr_reviews, "recommendation IN ('APPROVE', 'REQUEST_CHANGES', 'NEEDS_DISCUSSION') OR recommendation IS NULL", name: "pr_reviews_recommendation_check"
    add_check_constraint :pr_reviews, "risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') OR risk_level IS NULL", name: "pr_reviews_risk_level_check"
  end
end
