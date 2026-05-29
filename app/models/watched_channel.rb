class WatchedChannel < ApplicationRecord
  self.primary_key = "channel_id"

  enum :capture_mode, { full_stream: 0, involvement_only: 1, ignored: 2 }

  validates :channel_id, :channel_name, :capture_mode, presence: true

  scope :enabled, -> { where(enabled: true) }
end
