class CreateDeveloperNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :developer_notes, id: :uuid do |t|
      t.references :developer, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.text :note_type
      t.text :content, null: false
      t.timestamps
    end

    add_check_constraint :developer_notes, "note_type IN ('good', 'growth', 'concern', 'context') OR note_type IS NULL", name: "developer_notes_type_check"
  end
end
