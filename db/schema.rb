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

ActiveRecord::Schema[8.1].define(version: 2026_05_24_165757) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

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

  create_table "slack_threads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "captured_at", default: -> { "now()" }
    t.text "category"
    t.datetime "created_at", null: false
    t.text "keywords", array: true
    t.text "obsidian_path"
    t.text "participants", array: true
    t.jsonb "raw_messages", default: []
    t.text "slack_channel_id", null: false
    t.text "slack_channel_name"
    t.text "slack_thread_ts", null: false
    t.text "slack_url"
    t.text "summary"
    t.text "title"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_slack_threads_on_category"
    t.index ["keywords"], name: "index_slack_threads_on_keywords", using: :gin
    t.index ["slack_channel_id", "slack_thread_ts"], name: "index_slack_threads_on_slack_channel_id_and_slack_thread_ts", unique: true
    t.index ["slack_thread_ts"], name: "index_slack_threads_on_slack_thread_ts", unique: true
    t.check_constraint "category = ANY (ARRAY['architecture'::text, 'stakeholder'::text, 'team-decision'::text, 'incident'::text, 'other'::text])", name: "slack_threads_category_check"
  end

  add_foreign_key "delegations", "developers", on_delete: :nullify
  add_foreign_key "developer_notes", "developers", on_delete: :cascade
  add_foreign_key "oneone_sessions", "developers", on_delete: :cascade
end
