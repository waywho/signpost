class ConvertActionItemStatusToInteger < ActiveRecord::Migration[8.1]
  STATUS_MAP = { "pending" => 0, "actioned" => 1, "dismissed" => 2, "ignored" => 3, "resolved" => 4 }.freeze

  def up
    add_column :action_items, :status_int, :integer

    STATUS_MAP.each do |text, int|
      execute "UPDATE action_items SET status_int = #{int} WHERE status = '#{text}'"
    end

    change_column_null :action_items, :status_int, false, 0
    remove_column :action_items, :status
    rename_column :action_items, :status_int, :status
  end

  def down
    add_column :action_items, :status_text, :text

    STATUS_MAP.each do |text, int|
      execute "UPDATE action_items SET status_text = '#{text}' WHERE status = #{int}"
    end

    remove_column :action_items, :status
    rename_column :action_items, :status_text, :status
  end
end
