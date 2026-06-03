class Settings::OpenaisController < ApplicationController
  def show
    load_data
  end

  def update
    if params[:openai_api_key].present?
      EncryptedSetting.set("credentials", "openai_api_key", params[:openai_api_key])
    end
    load_data
    render :show
  end

  private

  def load_data
    @has_openai_key = EncryptedSetting.get("credentials", "openai_api_key").present?
  end
end
