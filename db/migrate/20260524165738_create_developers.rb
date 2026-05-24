class CreateDevelopers < ActiveRecord::Migration[8.1]
  def change
    create_table :developers, id: :uuid do |t|
      t.text :name, null: false
      t.text :role
      t.text :level
      t.text :github_handle
      t.text :slack_handle
      t.text :color
      t.date :joined_team
      t.text :career_goals
      t.text :strengths
      t.text :growth_areas
      t.text :private_notes
      t.jsonb :skills, default: []

      t.timestamps
    end

    add_check_constraint :developers, "level IN ('Junior', 'Mid', 'Senior', 'Staff')", name: "developers_level_check"
  end
end
