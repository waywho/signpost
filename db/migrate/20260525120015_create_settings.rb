class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings, id: false do |t|
      t.text :scope, null: false
      t.text :key, null: false
      t.jsonb :value, null: false
      t.timestamps
    end

    execute "ALTER TABLE settings ADD PRIMARY KEY (scope, key)"
  end
end
