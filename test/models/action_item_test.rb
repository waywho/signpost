require "test_helper"

class ActionItemTest < ActiveSupport::TestCase
  test "valid action_type values accepted" do
    %w[create_ticket delegate acknowledge discuss ignore].each do |type|
      item = build(:action_item, action_type: type, status: type == "ignore" ? "ignored" : "pending")
      assert item.valid?, "Expected action_type '#{type}' to be valid, got: #{item.errors.full_messages}"
    end
  end

  test "invalid action_type rejected" do
    item = build(:action_item, action_type: "invalid")
    assert_not item.valid?
  end

  test "ignored status accepted" do
    item = build(:action_item, status: "ignored", action_type: "ignore")
    assert item.valid?
  end

  test "scope actionable returns create_ticket and delegate" do
    create(:action_item, action_type: "create_ticket")
    create(:action_item, action_type: "delegate")
    create(:action_item, action_type: "acknowledge")
    create(:action_item, action_type: "discuss")
    create(:action_item, action_type: "ignore", status: "ignored")

    assert_equal 2, ActionItem.actionable.count
  end

  test "scope discussions returns discuss items" do
    create(:action_item, action_type: "discuss")
    create(:action_item, action_type: "delegate")

    assert_equal 1, ActionItem.discussions.count
  end

  test "scope acknowledgements returns acknowledge items" do
    create(:action_item, action_type: "acknowledge")
    create(:action_item, action_type: "delegate")

    assert_equal 1, ActionItem.acknowledgements.count
  end

  test "scope ignored returns ignored items" do
    create(:action_item, action_type: "ignore", status: "ignored")
    create(:action_item, action_type: "delegate")

    assert_equal 1, ActionItem.ignored.count
  end
end
