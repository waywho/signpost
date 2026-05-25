class CreateWatchedChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :watched_channels, id: false do |t|
      t.text :channel_id, null: false, primary_key: true
      t.text :channel_name, null: false
      t.text :capture_mode, null: false
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end

    add_check_constraint :watched_channels, "capture_mode IN ('full_stream', 'involvement_only', 'ignored')", name: "watched_channels_capture_mode_check"
  end
end
