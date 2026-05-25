class CreateNoiseFilters < ActiveRecord::Migration[8.1]
  def change
    create_table :noise_filters, id: :uuid do |t|
      t.text :category, null: false
      t.text :description, null: false
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end
  end
end
