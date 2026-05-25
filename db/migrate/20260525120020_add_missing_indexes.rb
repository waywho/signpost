class AddMissingIndexes < ActiveRecord::Migration[8.1]
  def change
    # developers — ordered by name, looked up by handles
    add_index :developers, :name
    add_index :developers, :github_handle
    add_index :developers, :slack_handle

    # commitments — filtered by done, ordered by done_at
    add_index :commitments, :done
    add_index :commitments, :done_at

    # delegations — ordered by delegated_at, filtered by issue_type
    add_index :delegations, :delegated_at
    add_index :delegations, :issue_type

    # developer_notes — filtered by note_type and created_at
    add_index :developer_notes, :note_type
    add_index :developer_notes, :created_at

    # pr_reviews — ordered by reviewed_at
    add_index :pr_reviews, :reviewed_at

    # slack_threads — filtered by captured_at, pending_reanalysis, compressed
    add_index :slack_threads, :captured_at
    add_index :slack_threads, :pending_reanalysis, where: "pending_reanalysis = TRUE"
    add_index :slack_threads, :compressed, where: "compressed = FALSE"

    # slack_topics — filtered by status, created_at
    add_index :slack_topics, :status
    add_index :slack_topics, :created_at

    # noise_filters — filtered by enabled
    add_index :noise_filters, :enabled, where: "enabled = TRUE"

    # git_hub_activities — filtered by event_type
    add_index :git_hub_activities, :event_type
  end
end
