class Settings::CalendarsController < ApplicationController
  def show
    load_data
  end

  def update
    if params[:google_ical_url].present?
      EncryptedSetting.set("credentials", "google_ical_url", params[:google_ical_url])
    end
    load_data
    render :show
  end

  private

  def load_data
    @has_google_ical_url = EncryptedSetting.get("credentials", "google_ical_url").present?
  end
end
