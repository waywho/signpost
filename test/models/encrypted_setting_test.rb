require "test_helper"

class EncryptedSettingTest < ActiveSupport::TestCase
  test "set and get a secret" do
    EncryptedSetting.set("credentials", "test_secret", "super-secret-value")
    assert_equal "super-secret-value", EncryptedSetting.get("credentials", "test_secret")
  end

  test "get returns nil when missing" do
    assert_nil EncryptedSetting.get("credentials", "nonexistent")
  end

  test "set upserts existing key" do
    EncryptedSetting.set("credentials", "upsert_key", "v1")
    EncryptedSetting.set("credentials", "upsert_key", "v2")
    assert_equal "v2", EncryptedSetting.get("credentials", "upsert_key")
  end

  test "value is encrypted in database" do
    EncryptedSetting.set("credentials", "secret_check", "plaintext-value")
    raw = ActiveRecord::Base.connection.select_value(
      "SELECT value FROM encrypted_settings WHERE scope = 'credentials' AND key = 'secret_check'"
    )
    assert_not_equal "plaintext-value", raw
  end
end
