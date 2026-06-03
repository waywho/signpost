require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get settings_path
    assert_response :success
    assert_select "h1", "Settings"
  end

  test "should update github settings" do
    patch settings_github_path, params: { github_username: "testuser", github_repos: [ "org/repo1", "org/repo2" ] }
    assert_response :success
    assert_equal "testuser", Setting.get("global", "github_username")
    assert_equal [ "org/repo1", "org/repo2" ], Setting.get("global", "github_repos")
  end

  test "should update slack capture settings" do
    patch settings_slack_path, params: { form: "capture", slack_capture_mode: "poll", slack_brain_emoji: "eyes", poll_interval_minutes: "30" }
    assert_response :success
    assert_equal "poll", Setting.get("global", "slack_capture_mode")
    assert_equal "eyes", Setting.get("global", "slack_brain_emoji")
    assert_equal 30, Setting.get("global", "poll_interval_minutes")
  end

  test "should add watched channel" do
    assert_difference("WatchedChannel.count") do
      post settings_watched_channels_path, params: { channel_select: "CNEW|new-channel", capture_mode: "full_stream" }
    end
    assert_response :success
  end

  test "should remove watched channel" do
    WatchedChannel.create!(channel_id: "CDEL", channel_name: "delete-me", capture_mode: "full_stream")
    assert_difference("WatchedChannel.count", -1) do
      delete settings_watched_channel_path("CDEL")
    end
  end

  test "should add noise filter" do
    assert_difference("NoiseFilter.count") do
      post settings_noise_filters_path, params: { filter_category: "test_filter", filter_description: "Test filter" }
    end
  end

  test "should remove noise filter" do
    filter = NoiseFilter.create!(category: "removeme", description: "To remove")
    assert_difference("NoiseFilter.count", -1) do
      delete settings_noise_filter_path(filter.id)
    end
  end
end
