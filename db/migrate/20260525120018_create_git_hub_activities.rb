class CreateGitHubActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :git_hub_activities, id: :uuid do |t|
      t.text :github_handle, null: false
      t.text :event_type, null: false
      t.text :repo
      t.text :title
      t.text :url
      t.timestamptz :occurred_at, null: false
      t.text :github_event_id
      t.timestamps
    end

    add_index :git_hub_activities, [:github_handle, :occurred_at]
    add_index :git_hub_activities, :github_event_id, unique: true
    add_check_constraint :git_hub_activities, "event_type IN ('commit', 'pr_opened', 'pr_merged', 'pr_review', 'issue_opened')", name: "git_hub_activities_event_type_check"
  end
end
