OpenAI.configure do |config|
  config.access_token = -> { EncryptedSetting.get("credentials", "openai_api_key") }
end
