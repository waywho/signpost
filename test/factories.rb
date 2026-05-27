FactoryBot.define do
  factory :action_item do
    association :slack_topic
    slack_thread { slack_topic.slack_thread }
    priority { 10 }
    status { "pending" }
    action_type { "delegate" }
    draft_title { "Fix login bug" }
    draft_body { "## Context\nLogin fails after OAuth redirect" }
  end

  factory :developer do
    name { "Alice" }
    role { "Backend Engineer" }
    level { "Senior" }
  end

  factory :oneone_session do
    developer
    session_date { Date.current }
    discussed { "Career growth and project status" }
    summary { "Good progress overall" }
  end

  factory :developer_note do
    developer
    note_type { "good" }
    content { "Great work on the API refactor" }
  end

  factory :delegation do
    summary { "Fix login bug" }
    urgency { "High" }
    status { "delegated" }
    delegated_at { Time.current }
  end

  factory :commitment do
    text { "Ship dashboard feature" }
    stakeholder { "Product team" }
    due_date { 3.days.from_now }
    done { false }
    source { "manual" }
  end

  factory :pr_review do
    sequence(:pr_number) { |n| n }
    repo { "myorg/myapp" }
    pr_title { "Add user authentication" }
    pr_author { "alice" }
    recommendation { "APPROVE" }
    risk_level { "LOW" }
    summary { "Clean implementation" }
    reviewed_at { Time.current }
  end

  factory :daily_log do
    sequence(:log_date) { |n| n.days.ago.to_date }
    eod_notes { "Shipped the dashboard feature" }
  end

  factory :slack_thread do
    slack_channel_id { "C123456" }
    sequence(:slack_thread_ts) { |n| "1716566400.#{n.to_s.rjust(6, '0')}" }
    slack_channel_name { "engineering" }
    title { "Architecture discussion" }
    category { "architecture" }
    summary { "Discussed new service boundaries" }
    status { "new" }
  end

  factory :slack_message do
    slack_thread
    sequence(:message_ts) { |n| "17165664#{n.to_s.rjust(6, '0')}.000001" }
    content { "Hello from Slack" }
    user_name { "Alice" }
    message_ts_at { 1.hour.ago }
  end

  factory :slack_topic do
    slack_thread
    title { "Bug report" }
    summary { "A bug was found in the login flow" }
    status { "open" }
    urgency { "high" }
    category { "bug" }
  end

  factory :slack_topic_message do
    slack_topic
    slack_message
  end

  factory :watched_channel do
    sequence(:channel_id) { |n| "C#{n.to_s.rjust(6, '0')}" }
    channel_name { "engineering" }
    capture_mode { "full_stream" }
    enabled { true }
  end

  factory :noise_filter do
    sequence(:category) { |n| "filter_#{n}" }
    description { "Test noise filter" }
    enabled { true }
  end

  factory :setting do
    sequence(:key) { |n| "test_key_#{n}" }
    scope { "global" }
    value { "test_value" }
  end

  factory :encrypted_setting do
    scope { "credentials" }
    sequence(:key) { |n| "test_secret_#{n}" }
    value { "secret_value" }
  end

  factory :watched_repo do
    sequence(:full_name) { |n| "org/repo-#{n}" }
    enabled { true }
  end
end
