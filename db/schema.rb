# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_25_082642) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "action_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "approved_at"
    t.datetime "created_at", null: false
    t.uuid "delegation_id"
    t.timestamptz "dismissed_at"
    t.text "draft_body"
    t.text "draft_title"
    t.text "github_issue_url"
    t.integer "priority", null: false
    t.jsonb "related_items", default: []
    t.uuid "slack_thread_id", null: false
    t.uuid "slack_topic_id", null: false
    t.text "status", default: "pending", null: false
    t.uuid "suggested_developer_id"
    t.text "suggested_repo"
    t.text "suggestion_reason"
    t.datetime "updated_at", null: false
    t.index ["delegation_id"], name: "index_action_items_on_delegation_id"
    t.index ["priority"], name: "index_action_items_on_priority"
    t.index ["slack_thread_id"], name: "index_action_items_on_slack_thread_id"
    t.index ["slack_topic_id"], name: "index_action_items_on_slack_topic_id", unique: true
    t.index ["status"], name: "index_action_items_on_status"
    t.index ["suggested_developer_id"], name: "index_action_items_on_suggested_developer_id"
    t.check_constraint "status = ANY (ARRAY['pending'::text, 'approved'::text, 'dismissed'::text])", name: "action_items_status_check"
  end

  create_table "commitments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "done", default: false
    t.timestamptz "done_at"
    t.date "due_date"
    t.text "slack_thread_url"
    t.text "source"
    t.text "stakeholder"
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_commitments_on_due_date", where: "(done = false)"
    t.check_constraint "source = ANY (ARRAY['manual'::text, 'slack'::text, 'meeting'::text])", name: "commitments_source_check"
  end

  create_table "daily_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "eod_notes"
    t.date "log_date", null: false
    t.jsonb "tomorrow_priorities", default: []
    t.datetime "updated_at", null: false
    t.index ["log_date"], name: "index_daily_logs_on_log_date", unique: true
  end

  create_table "delegations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "codebase_context"
    t.datetime "created_at", null: false
    t.timestamptz "delegated_at", default: -> { "now()" }
    t.uuid "developer_id"
    t.text "developer_name"
    t.text "github_issue_url"
    t.text "handoff_message"
    t.text "issue_type"
    t.timestamptz "resolved_at"
    t.text "slack_channel_id"
    t.text "slack_thread_ts"
    t.text "source_channel"
    t.text "source_user"
    t.text "status", default: "delegated"
    t.text "summary", null: false
    t.datetime "updated_at", null: false
    t.text "urgency"
    t.index ["developer_id"], name: "index_delegations_on_developer_id"
    t.index ["status"], name: "index_delegations_on_status"
    t.check_constraint "status = ANY (ARRAY['delegated'::text, 'in_progress'::text, 'done'::text, 'blocked'::text])", name: "delegations_status_check"
    t.check_constraint "urgency = ANY (ARRAY['Critical'::text, 'High'::text, 'Medium'::text, 'Low'::text])", name: "delegations_urgency_check"
  end

  create_table "developer_notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.uuid "developer_id", null: false
    t.text "note_type"
    t.datetime "updated_at", null: false
    t.index ["developer_id"], name: "index_developer_notes_on_developer_id"
    t.check_constraint "note_type = ANY (ARRAY['good'::text, 'growth'::text, 'concern'::text, 'context'::text])", name: "developer_notes_type_check"
  end

  create_table "developers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "career_goals"
    t.text "color"
    t.datetime "created_at", null: false
    t.text "github_handle"
    t.text "growth_areas"
    t.date "joined_team"
    t.text "level"
    t.text "name", null: false
    t.text "private_notes"
    t.text "role"
    t.jsonb "skills", default: []
    t.text "slack_handle"
    t.text "strengths"
    t.datetime "updated_at", null: false
    t.check_constraint "level = ANY (ARRAY['Junior'::text, 'Mid'::text, 'Senior'::text, 'Staff'::text])", name: "developers_level_check"
  end

  create_table "encrypted_settings", primary_key: ["scope", "key"], force: :cascade do |t|
    t.text "key", null: false
    t.text "scope", null: false
    t.timestamptz "updated_at", default: -> { "now()" }
    t.text "value", null: false
  end

  create_table "noise_filters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "category", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "updated_at", null: false
  end

  create_table "oneone_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "action_items"
    t.text "challenges"
    t.datetime "created_at", null: false
    t.uuid "developer_id", null: false
    t.text "discussed"
    t.text "growth"
    t.text "private_notes"
    t.date "session_date", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.text "wins"
    t.index ["developer_id"], name: "index_oneone_sessions_on_developer_id"
    t.index ["session_date"], name: "index_oneone_sessions_on_session_date"
  end

  create_table "pr_reviews", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "additions"
    t.jsonb "business_logic_risk", default: {}
    t.datetime "created_at", null: false
    t.jsonb "critical_flags", default: []
    t.jsonb "ddd_issues", default: []
    t.integer "deletions"
    t.text "draft_comment"
    t.integer "files_changed"
    t.jsonb "missing_tests", default: []
    t.jsonb "oop_issues", default: []
    t.text "pr_author"
    t.integer "pr_number", null: false
    t.text "pr_title"
    t.text "recommendation"
    t.text "repo", null: false
    t.timestamptz "reviewed_at", default: -> { "now()" }
    t.jsonb "risk_areas", default: []
    t.text "risk_level"
    t.text "summary"
    t.datetime "updated_at", null: false
    t.index ["repo"], name: "index_pr_reviews_on_repo"
    t.check_constraint "recommendation = ANY (ARRAY['APPROVE'::text, 'REQUEST_CHANGES'::text, 'NEEDS_DISCUSSION'::text])", name: "pr_reviews_recommendation_check"
    t.check_constraint "risk_level = ANY (ARRAY['LOW'::text, 'MEDIUM'::text, 'HIGH'::text, 'CRITICAL'::text])", name: "pr_reviews_risk_level_check"
  end

  create_table "settings", primary_key: ["scope", "key"], force: :cascade do |t|
    t.text "key", null: false
    t.text "scope", null: false
    t.timestamptz "updated_at", default: -> { "now()" }
    t.jsonb "value", null: false
  end

  create_table "slack_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "content", null: false
    t.timestamptz "created_at", default: -> { "now()" }
    t.vector "embedding", limit: 1536
    t.text "mentioned_users", array: true
    t.text "message_ts", null: false
    t.timestamptz "message_ts_at"
    t.uuid "slack_thread_id", null: false
    t.text "user_id"
    t.text "user_name"
    t.index ["embedding"], name: "index_slack_messages_on_embedding", opclass: :vector_cosine_ops, using: :hnsw
    t.index ["mentioned_users"], name: "index_slack_messages_on_mentioned_users", using: :gin
    t.index ["slack_thread_id", "message_ts"], name: "index_slack_messages_on_slack_thread_id_and_message_ts", unique: true
    t.index ["slack_thread_id"], name: "index_slack_messages_on_slack_thread_id"
  end

  create_table "slack_threads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "capture_reason"
    t.timestamptz "captured_at", default: -> { "now()" }
    t.text "category"
    t.boolean "compressed", default: false, null: false
    t.datetime "created_at", null: false
    t.vector "embedding", limit: 1536
    t.text "keywords", array: true
    t.timestamptz "last_analyzed_at"
    t.text "obsidian_path"
    t.text "participants", array: true
    t.boolean "pending_reanalysis", default: false, null: false
    t.jsonb "raw_messages", default: []
    t.text "slack_channel_id", null: false
    t.text "slack_channel_name"
    t.text "slack_thread_ts", null: false
    t.text "slack_url"
    t.text "status", default: "new", null: false
    t.text "summary"
    t.text "title"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_slack_threads_on_category"
    t.index ["embedding"], name: "index_slack_threads_on_embedding", opclass: :vector_cosine_ops, using: :hnsw
    t.index ["keywords"], name: "index_slack_threads_on_keywords", using: :gin
    t.index ["slack_channel_id", "slack_thread_ts"], name: "index_slack_threads_on_slack_channel_id_and_slack_thread_ts", unique: true
    t.index ["slack_thread_ts"], name: "index_slack_threads_on_slack_thread_ts", unique: true
    t.check_constraint "(capture_reason = ANY (ARRAY['mention'::text, 'participation'::text, 'brain_emoji'::text, 'channel_stream'::text, 'manual'::text])) OR capture_reason IS NULL", name: "slack_threads_capture_reason_check"
    t.check_constraint "category = ANY (ARRAY['architecture'::text, 'stakeholder'::text, 'team-decision'::text, 'incident'::text, 'other'::text])", name: "slack_threads_category_check"
    t.check_constraint "status = ANY (ARRAY['new'::text, 'triaged'::text, 'actioned'::text, 'archived'::text])", name: "slack_threads_status_check"
  end

  create_table "slack_topic_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "slack_message_id", null: false
    t.uuid "slack_topic_id", null: false
    t.index ["slack_message_id"], name: "index_slack_topic_messages_on_slack_message_id"
    t.index ["slack_topic_id", "slack_message_id"], name: "idx_topic_messages_unique", unique: true
    t.index ["slack_topic_id"], name: "index_slack_topic_messages_on_slack_topic_id"
  end

  create_table "slack_topics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "action_recommendation"
    t.text "category"
    t.datetime "created_at", null: false
    t.vector "embedding", limit: 1536
    t.uuid "slack_thread_id", null: false
    t.text "status", default: "open", null: false
    t.text "summary", null: false
    t.text "title", null: false
    t.datetime "updated_at", null: false
    t.text "urgency"
    t.index ["embedding"], name: "index_slack_topics_on_embedding", opclass: :vector_cosine_ops, using: :hnsw
    t.index ["slack_thread_id"], name: "index_slack_topics_on_slack_thread_id"
    t.check_constraint "status = ANY (ARRAY['open'::text, 'actioned'::text, 'dismissed'::text])", name: "slack_topics_status_check"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "watched_channels", primary_key: "channel_id", id: :text, force: :cascade do |t|
    t.timestamptz "added_at", default: -> { "now()" }
    t.text "capture_mode", null: false
    t.text "channel_name", null: false
    t.boolean "enabled", default: true, null: false
    t.check_constraint "capture_mode = ANY (ARRAY['full_stream'::text, 'involvement_only'::text, 'ignored'::text])", name: "watched_channels_capture_mode_check"
  end

  create_table "watched_repos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled"
    t.text "full_name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "action_items", "delegations"
  add_foreign_key "action_items", "developers", column: "suggested_developer_id"
  add_foreign_key "action_items", "slack_threads"
  add_foreign_key "action_items", "slack_topics", on_delete: :cascade
  add_foreign_key "delegations", "developers", on_delete: :nullify
  add_foreign_key "developer_notes", "developers", on_delete: :cascade
  add_foreign_key "oneone_sessions", "developers", on_delete: :cascade
  add_foreign_key "slack_messages", "slack_threads", on_delete: :cascade
  add_foreign_key "slack_topic_messages", "slack_messages", on_delete: :cascade
  add_foreign_key "slack_topic_messages", "slack_topics", on_delete: :cascade
  add_foreign_key "slack_topics", "slack_threads", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
