class AddResolvedStatusToActionItems < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :action_items, name: "action_items_status_check"
    add_check_constraint :action_items, "status IN ('pending', 'actioned', 'dismissed', 'ignored', 'resolved')", name: "action_items_status_check"
  end
end
