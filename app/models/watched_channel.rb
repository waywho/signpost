class WatchedChannel < ApplicationRecord
  self.primary_key = "channel_id"

  validates :channel_id, :channel_name, :capture_mode, presence: true
  validates :capture_mode, inclusion: { in: %w[full_stream involvement_only ignored] }

  scope :enabled, -> { where(enabled: true) }
  scope :full_stream, -> { enabled.where(capture_mode: "full_stream") }
end
