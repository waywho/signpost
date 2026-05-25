class CreateWatchedRepos < ActiveRecord::Migration[8.1]
  def change
    create_table :watched_repos, id: :uuid do |t|
      t.text :full_name
      t.boolean :enabled

      t.timestamps
    end
  end
end
