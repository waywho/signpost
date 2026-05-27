class AddLastPolledAtToWatchedChannels < ActiveRecord::Migration[8.1]
  def change
    add_column :watched_channels, :last_polled_at, :datetime
  end
end
