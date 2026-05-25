require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get settings_path
    assert_response :success
    assert_select "h1", "Settings"
  end

  test "should update github settings" do
    patch settings_path, params: { section: "github", github_username: "testuser", github_repos: "org/repo1, org/repo2" }
    assert_redirected_to settings_path
    assert_equal "testuser", Setting.get("global", "github_username")
    assert_equal ["org/repo1", "org/repo2"], Setting.get("global", "github_repos")
  end

  test "should update slack settings" do
    patch settings_path, params: { section: "slack", slack_capture_mode: "poll", slack_brain_emoji: "eyes", poll_interval_minutes: "30" }
    assert_redirected_to settings_path
    assert_equal "poll", Setting.get("global", "slack_capture_mode")
    assert_equal "eyes", Setting.get("global", "slack_brain_emoji")
    assert_equal 30, Setting.get("global", "poll_interval_minutes")
  end

  test "should add watched channel" do
    assert_difference("WatchedChannel.count") do
      patch settings_path, params: { section: "watched_channel_add", channel_id: "CNEW", channel_name: "new-channel", capture_mode: "full_stream" }
    end
    assert_redirected_to settings_path
  end

  test "should remove watched channel" do
    WatchedChannel.create!(channel_id: "CDEL", channel_name: "delete-me", capture_mode: "full_stream")
    assert_difference("WatchedChannel.count", -1) do
      patch settings_path, params: { section: "watched_channel_remove", channel_id: "CDEL" }
    end
  end

  test "should add noise filter" do
    assert_difference("NoiseFilter.count") do
      patch settings_path, params: { section: "noise_filter_add", filter_category: "test_filter", filter_description: "Test filter" }
    end
  end

  test "should remove noise filter" do
    filter = NoiseFilter.create!(category: "removeme", description: "To remove")
    assert_difference("NoiseFilter.count", -1) do
      patch settings_path, params: { section: "noise_filter_remove", filter_id: filter.id }
    end
  end
end
