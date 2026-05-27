class AddActionTypeToActionItems < ActiveRecord::Migration[8.1]
  def up
    add_column :action_items, :action_type, :string, null: false, default: "delegate"

    # Update existing status check constraint to include "ignored"
    remove_check_constraint :action_items, name: "action_items_status_check"
    add_check_constraint :action_items, "status IN ('pending', 'approved', 'dismissed', 'ignored')", name: "action_items_status_check"

    # Add check constraint for action_type
    add_check_constraint :action_items, "action_type IN ('create_ticket', 'delegate', 'acknowledge', 'discuss', 'ignore')", name: "action_items_action_type_check"

    add_index :action_items, :action_type
  end

  def down
    remove_index :action_items, :action_type
    remove_check_constraint :action_items, name: "action_items_action_type_check"
    remove_check_constraint :action_items, name: "action_items_status_check"
    add_check_constraint :action_items, "status IN ('pending', 'approved', 'dismissed')", name: "action_items_status_check"
    remove_column :action_items, :action_type
  end
end
