class CreateWatchedRepos < ActiveRecord::Migration[8.1]
  def change
    create_table :watched_repos, id: :uuid do |t|
      t.text :full_name, null: false
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end

    add_index :watched_repos, :full_name, unique: true
  end
end
