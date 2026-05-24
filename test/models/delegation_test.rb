require "test_helper"

class DelegationTest < ActiveSupport::TestCase
  test "valid with summary" do
    delegation = Delegation.new(summary: "Fix login bug")
    assert delegation.valid?
  end

  test "invalid without summary" do
    delegation = Delegation.new
    assert_not delegation.valid?
  end

  test "defaults to delegated status" do
    delegation = Delegation.create!(summary: "Fix login bug")
    assert_equal "delegated", delegation.status
  end

  test "active scope excludes done" do
    Delegation.delete_all
    Delegation.create!(summary: "Done task", status: "done")
    Delegation.create!(summary: "Active task", status: "in_progress")
    assert_equal 1, Delegation.active.count
    assert_equal "Active task", Delegation.active.first.summary
  end
end
