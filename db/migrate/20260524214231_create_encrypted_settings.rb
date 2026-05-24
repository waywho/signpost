class CreateEncryptedSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :encrypted_settings, id: false do |t|
      t.text :scope, null: false
      t.text :key, null: false
      t.text :value, null: false
      t.timestamptz :updated_at, default: -> { "NOW()" }
    end

    execute "ALTER TABLE encrypted_settings ADD PRIMARY KEY (scope, key)"
  end
end
