require "test_helper"

class OneOnePrepServiceTest < ActiveSupport::TestCase
  test "prep returns briefing text" do
    developer = create(:developer)

    mock_claude = Object.new
    mock_claude.define_singleton_method(:analyze) { |prompt, **_| "## Suggested Talking Points\n- Discuss project progress" }

    mock_github = Object.new
    mock_github.define_singleton_method(:configured?) { false }

    service = OneOnePrepService.new(claude_service: mock_claude, github_service: mock_github)
    result = service.prep(developer)

    assert_includes result, "Suggested Talking Points"
  end

  test "handles developer with no data gracefully" do
    developer = create(:developer, name: "New Dev")

    mock_claude = Object.new
    mock_claude.define_singleton_method(:analyze) { |prompt, **_| "## Talking Points\n- Get to know each other" }

    mock_github = Object.new
    mock_github.define_singleton_method(:configured?) { false }

    service = OneOnePrepService.new(claude_service: mock_claude, github_service: mock_github)
    result = service.prep(developer)

    assert result.present?
  end
end
