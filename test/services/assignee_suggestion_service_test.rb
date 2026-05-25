require "test_helper"

class AssigneeSuggestionServiceTest < ActiveSupport::TestCase
  test "suggests developer with lowest workload" do
    busy_dev = create(:developer, name: "Busy", growth_areas: nil)
    free_dev = create(:developer, name: "Free", growth_areas: nil)
    3.times { create(:delegation, developer: busy_dev, status: "in_progress") }

    thread = create(:slack_thread)
    topic = create(:slack_topic, slack_thread: thread, category: "bug")

    result = AssigneeSuggestionService.new.suggest(topic)
    assert_equal free_dev, result[:developer]
  end

  test "boosts developer with matching growth area" do
    create(:developer, name: "Generic", growth_areas: "frontend")
    matched_dev = create(:developer, name: "Matched", growth_areas: "bug fixing, architecture")

    thread = create(:slack_thread)
    topic = create(:slack_topic, slack_thread: thread, category: "architecture")

    result = AssigneeSuggestionService.new.suggest(topic)
    assert_equal matched_dev, result[:developer]
    assert_includes result[:reason], "growth area matches"
  end

  test "returns nil when no developers" do
    thread = create(:slack_thread)
    topic = create(:slack_topic, slack_thread: thread)

    assert_nil AssigneeSuggestionService.new.suggest(topic)
  end
end
