require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "get returns value" do
    Setting.set("global", "test_key", "test_value")
    assert_equal "test_value", Setting.get("global", "test_key")
  end

  test "get returns default when missing" do
    assert_equal "fallback", Setting.get("global", "nonexistent", default: "fallback")
  end

  test "set upserts" do
    Setting.set("global", "upsert_key", "v1")
    Setting.set("global", "upsert_key", "v2")
    assert_equal "v2", Setting.get("global", "upsert_key")
  end
end
