require "test_helper"

class InsightsServiceTest < ActiveSupport::TestCase
  test "stale_oneones flags developer with old 1:1" do
    dev = create(:developer, created_at: 2.months.ago)
    create(:oneone_session, developer: dev, session_date: 30.days.ago)

    alerts = InsightsService.new.alerts
    stale = alerts.find { |a| a[:message].include?(dev.name) && a[:message].include?("1:1") }
    assert stale
    assert_equal "warning", stale[:type]
  end

  test "stale_oneones flags developer with no 1:1 ever" do
    dev = create(:developer, created_at: 2.months.ago)

    alerts = InsightsService.new.alerts
    never = alerts.find { |a| a[:message].include?(dev.name) && a[:message].include?("never") }
    assert never
  end

  test "stale_oneones skips recent 1:1" do
    dev = create(:developer)
    create(:oneone_session, developer: dev, session_date: 5.days.ago)

    alerts = InsightsService.new.alerts
    stale = alerts.find { |a| a[:message].include?(dev.name) && a[:message].include?("1:1") }
    assert_nil stale
  end

  test "overloaded_developers flags 5+ delegations" do
    dev = create(:developer)
    5.times { create(:delegation, developer: dev, status: "in_progress") }

    alerts = InsightsService.new.alerts
    overloaded = alerts.find { |a| a[:message].include?(dev.name) && a[:message].include?("active delegations") }
    assert overloaded
    assert_equal "danger", overloaded[:type]
  end

  test "overdue_commitments groups by stakeholder" do
    create(:commitment, stakeholder: "Product team", due_date: 5.days.ago)
    create(:commitment, stakeholder: "Product team", due_date: 3.days.ago)

    alerts = InsightsService.new.alerts
    overdue = alerts.find { |a| a[:message].include?("Product team") }
    assert overdue
    assert_includes overdue[:message], "2 overdue"
  end

  test "unresolved_concerns flags concern without follow-up" do
    dev = create(:developer)
    create(:developer_note, developer: dev, note_type: "concern", content: "Needs improvement")

    alerts = InsightsService.new.alerts
    concern = alerts.find { |a| a[:message].include?(dev.name) && a[:message].include?("concern") }
    assert concern
  end

  test "patterns returns cached data" do
    Setting.set("global", "daily_insights", [{ "message" => "test pattern" }])
    assert_equal [{ "message" => "test pattern" }], InsightsService.new.patterns
  end

  test "find_topic_clusters groups similar topics" do
    embedding = Array.new(1536, 0.1)
    thread = create(:slack_thread)
    create(:slack_topic, slack_thread: thread, title: "API timeout", embedding: embedding)
    create(:slack_topic, slack_thread: thread, title: "Request hanging", embedding: embedding)

    service = InsightsService.new
    data = service.send(:gather_pattern_data)
    assert data[:clusters].any?
    assert_equal 2, data[:clusters].first[:size]
  end

  test "find_topic_clusters skips dissimilar topics" do
    thread = create(:slack_thread)
    create(:slack_topic, slack_thread: thread, title: "A", embedding: Array.new(1536, 0.1))
    create(:slack_topic, slack_thread: thread, title: "B", embedding: Array.new(1536, -0.1))

    service = InsightsService.new
    data = service.send(:gather_pattern_data)
    assert_empty data[:clusters]
  end

  test "delegation_velocity flags declining developer" do
    dev = create(:developer)
    3.times do
      d = create(:delegation, developer: dev, status: "done")
      d.update_column(:resolved_at, 45.days.ago)
    end
    create(:delegation, developer: dev, status: "done")

    service = InsightsService.new
    velocity = service.send(:delegation_velocity)
    assert velocity.any? { |v| v[:name] == dev.name && v[:trend] == "declining" }
  end

  test "refresh_patterns runs without error" do
    service = InsightsService.new
    assert_nothing_raised { service.refresh_patterns }
  end
end
