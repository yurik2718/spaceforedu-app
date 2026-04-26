require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "super_admin? is true for super_admin role and false for student" do
    assert     users(:admin).super_admin?
    refute     users(:student_es).super_admin?
  end

  test "student? is true for student role and false for super_admin" do
    assert     users(:student_es).student?
    refute     users(:admin).student?
  end

  test "initials returns the first letter of the first two words, uppercased" do
    user = User.new(name: "ana maria", email_address: "x@example.com")

    assert_equal "AM", user.initials
  end

  test "initials uses one letter when name has a single word" do
    user = User.new(name: "Anna", email_address: "x@example.com")

    assert_equal "A", user.initials
  end

  test "initials falls back to the first email letter when name is blank" do
    user = User.new(name: "", email_address: "zoe@example.com")

    assert_equal "Z", user.initials
  end

  test "initials handles unicode names" do
    user = User.new(name: "Ñoño Élise", email_address: "x@example.com")

    assert_equal "ÑÉ", user.initials
  end

  test ".kept excludes soft-deleted users" do
    assert_includes     User.kept, users(:admin)
    assert_not_includes User.kept, users(:discarded_user)
  end

  test "DB check_constraint rejects unknown role when the model is bypassed" do
    assert_raises(ActiveRecord::StatementInvalid) do
      users(:admin).update_column(:role, "teacher")
    end
  end

  test "email_address validates uniqueness regardless of case" do
    invalid = User.new(email_address: "ADMIN@example.com", password: "secret", name: "Dup")

    refute invalid.valid?
    assert invalid.errors.added?(:email_address, :taken, value: "admin@example.com")
  end

  test "phone is stored encrypted at rest" do
    user = User.create!(
      email_address: "enc@example.com",
      password:      "secret",
      name:          "Enc",
      phone:         "+34000000000"
    )

    assert_equal "+34000000000", user.reload.phone

    raw = User.connection.select_value("SELECT phone FROM users WHERE id = #{user.id}")
    refute_equal "+34000000000", raw
    refute_nil raw
  end
end
