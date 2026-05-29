class CreateCodebaseAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :codebase_analyses, id: :uuid do |t|
      t.references :slack_thread, null: false, foreign_key: true, type: :uuid
      t.string :repo_name, null: false
      t.string :repo_path, null: false
      t.integer :status, null: false, default: 0
      t.text :prompt_context
      t.text :analysis
      t.string :draft_title
      t.text :draft_body
      t.text :error_message
      t.string :github_issue_url
      t.references :delegation, null: true, foreign_key: true, type: :uuid
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
