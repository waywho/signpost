class CreateDeveloperNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :developer_notes, id: :uuid do |t|
      t.references :developer, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.text :note_type
      t.text :content, null: false

      t.timestamps
    end

    add_check_constraint :developer_notes, "note_type IN ('good', 'growth', 'concern', 'context')", name: "developer_notes_type_check"
  end
end
