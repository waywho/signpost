class CreateCommitments < ActiveRecord::Migration[8.1]
  def change
    create_table :commitments, id: :uuid do |t|
      t.text :text, null: false
      t.text :stakeholder
      t.date :due_date
      t.boolean :done, default: false
      t.timestamptz :done_at
      t.text :source
      t.text :slack_thread_url

      t.timestamps
    end

    add_check_constraint :commitments, "source IN ('manual', 'slack', 'meeting')", name: "commitments_source_check"
    add_index :commitments, :due_date, where: "done = FALSE"
  end
end
