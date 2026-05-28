class RenameApprovedToActionedInActionItems < ActiveRecord::Migration[8.1]
  def change
    rename_column :action_items, :approved_at, :actioned_at

    remove_check_constraint :action_items, name: "action_items_status_check"
    add_check_constraint :action_items, "status IN ('pending', 'actioned', 'dismissed', 'ignored')", name: "action_items_status_check"

    reversible do |dir|
      dir.up { ActionItem.where(status: "approved").update_all(status: "actioned") }
      dir.down { ActionItem.where(status: "actioned").update_all(status: "approved") }
    end
  end
end
