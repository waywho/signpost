class CreateDailyLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_logs, id: :uuid do |t|
      t.date :log_date, null: false
      t.text :eod_notes
      t.jsonb :tomorrow_priorities, default: []
      t.timestamps
    end

    add_index :daily_logs, :log_date, unique: true
  end
end
