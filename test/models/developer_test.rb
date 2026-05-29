require "test_helper"

class DeveloperTest < ActiveSupport::TestCase
  test "valid with name only" do
    developer = Developer.new(name: "Alice")
    assert developer.valid?
  end

  test "invalid without name" do
    developer = Developer.new
    assert_not developer.valid?
    assert_includes developer.errors[:name], "can't be blank"
  end

  test "validates level inclusion" do
    assert_raises(ArgumentError) { Developer.new(name: "Alice", level: "Intern") }
  end

  test "allows valid levels" do
    %w[junior mid senior staff].each do |level|
      developer = Developer.new(name: "Alice", level: level)
      assert developer.valid?, "Expected #{level} to be valid"
    end
  end
end
