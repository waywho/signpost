class ConvertAllStringColumnsToIntegerEnums < ActiveRecord::Migration[8.1]
  def up
    # Remove all check constraints first (before columns get dropped)
    remove_check_constraint :action_items, name: "action_items_action_type_check"
    remove_check_constraint :slack_topics, name: "slack_topics_status_check"
    remove_check_constraint :slack_threads, name: "slack_threads_category_check"
    remove_check_constraint :slack_threads, name: "slack_threads_status_check"
    remove_check_constraint :slack_threads, name: "slack_threads_capture_reason_check"
    remove_check_constraint :pr_reviews, name: "pr_reviews_recommendation_check"
    remove_check_constraint :pr_reviews, name: "pr_reviews_risk_level_check"
    remove_check_constraint :delegations, name: "delegations_urgency_check"
    remove_check_constraint :delegations, name: "delegations_status_check"
    remove_check_constraint :developer_notes, name: "developer_notes_type_check"
    remove_check_constraint :commitments, name: "commitments_source_check"
    remove_check_constraint :watched_channels, name: "watched_channels_capture_mode_check"
    remove_check_constraint :developers, name: "developers_level_check"

    # ActionItem: action_type
    convert(:action_items, :action_type,
      { "create_ticket" => 0, "delegate" => 1, "acknowledge" => 2, "discuss" => 3, "ignore" => 4 })

    # SlackTopic: category, urgency, action_recommendation, status
    convert(:slack_topics, :category,
      { "bug" => 0, "feature" => 1, "question" => 2, "incident" => 3, "architecture" => 4, "process" => 5, "other" => 6 },
      nullable: true)
    convert(:slack_topics, :urgency,
      { "critical" => 0, "high" => 1, "medium" => 2, "low" => 3 },
      nullable: true)
    convert(:slack_topics, :action_recommendation,
      { "delegate" => 0, "create_ticket" => 1, "acknowledge" => 2, "discuss" => 3, "ignore" => 4 },
      nullable: true)
    convert(:slack_topics, :status,
      { "open" => 0, "actioned" => 1, "dismissed" => 2 })

    # SlackThread: category, status, capture_reason
    # "team-decision" becomes "team_decision" in enum
    convert(:slack_threads, :category,
      { "architecture" => 0, "stakeholder" => 1, "team-decision" => 2, "incident" => 3, "other" => 4 },
      nullable: true)
    convert(:slack_threads, :status,
      { "new" => 0, "triaged" => 1, "actioned" => 2, "archived" => 3 })
    convert(:slack_threads, :capture_reason,
      { "mention" => 0, "participation" => 1, "brain_emoji" => 2, "channel_stream" => 3, "manual" => 4 },
      nullable: true)

    # PrReview: recommendation, risk_level (UPPERCASE -> lowercase enum keys)
    convert(:pr_reviews, :recommendation,
      { "APPROVE" => 0, "REQUEST_CHANGES" => 1, "NEEDS_DISCUSSION" => 2 },
      nullable: true)
    convert(:pr_reviews, :risk_level,
      { "LOW" => 0, "MEDIUM" => 1, "HIGH" => 2, "CRITICAL" => 3 },
      nullable: true)

    # Delegation: urgency, status (Capitalized -> lowercase enum keys)
    convert(:delegations, :urgency,
      { "Critical" => 0, "High" => 1, "Medium" => 2, "Low" => 3 },
      nullable: true)
    convert(:delegations, :status,
      { "delegated" => 0, "in_progress" => 1, "done" => 2, "blocked" => 3 })

    # DeveloperNote: note_type
    convert(:developer_notes, :note_type,
      { "good" => 0, "growth" => 1, "concern" => 2, "context" => 3 },
      nullable: true)

    # Commitment: source
    convert(:commitments, :source,
      { "manual" => 0, "slack" => 1, "meeting" => 2 },
      nullable: true)

    # WatchedChannel: capture_mode
    convert(:watched_channels, :capture_mode,
      { "full_stream" => 0, "involvement_only" => 1, "ignored" => 2 })

    # Developer: level (Capitalized -> lowercase enum keys)
    convert(:developers, :level,
      { "Junior" => 0, "Mid" => 1, "Senior" => 2, "Staff" => 3 },
      nullable: true)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def convert(table, column, mapping, nullable: false)
    add_column table, :"#{column}_int", :integer
    mapping.each do |text, int|
      execute "UPDATE #{table} SET #{column}_int = #{int} WHERE #{column} = #{connection.quote(text)}"
    end
    change_column_null table, :"#{column}_int", false, 0 unless nullable
    remove_column table, column
    rename_column table, :"#{column}_int", column
  end
end
