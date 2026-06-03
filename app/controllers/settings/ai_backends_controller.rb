class Settings::AiBackendsController < ApplicationController
  def show
    load_data
  end

  def update
    if params[:ai_backend].in?(ClaudeService::BACKENDS)
      Setting.set("global", "ai_backend", params[:ai_backend])
    end
    if params[:anthropic_api_key].present?
      EncryptedSetting.set("credentials", "anthropic_api_key", params[:anthropic_api_key])
    end
    load_data
    render :show
  end

  private

  def load_data
    @ai_backend = Setting.get("global", "ai_backend", default: "cli")
    @has_anthropic_key = EncryptedSetting.get("credentials", "anthropic_api_key").present?
  end
end
