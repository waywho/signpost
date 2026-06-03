class Settings::ArchivesController < ApplicationController
  ARCHIVE_KEYS = %w[compression_after_months reanalysis_message_threshold reanalysis_quiet_minutes].freeze

  def show
    load_data
  end

  def update
    ARCHIVE_KEYS.each do |key|
      next if params[key].blank?
      Setting.set("global", key, params[key].to_i)
    end
    load_data
    render :show
  end

  private

  def load_data
    @compression_after_months = Setting.get("global", "compression_after_months", default: 6)
    @reanalysis_message_threshold = Setting.get("global", "reanalysis_message_threshold", default: 3)
    @reanalysis_quiet_minutes = Setting.get("global", "reanalysis_quiet_minutes", default: 30)
  end
end
