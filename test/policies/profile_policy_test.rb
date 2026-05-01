require "test_helper"

class ProfilePolicyTest < ActiveSupport::TestCase
  setup do
    @student = users(:student_es)
    @other   = users(:student_other)
    @admin   = users(:admin)
  end

  test "show? is true only when user is the record" do
    assert ProfilePolicy.new(@student, @student).show?
    refute ProfilePolicy.new(@student, @other).show?
    refute ProfilePolicy.new(nil,      @student).show?
  end

  test "update? mirrors show?" do
    assert ProfilePolicy.new(@student, @student).update?
    refute ProfilePolicy.new(@other,   @student).update?
    refute ProfilePolicy.new(nil,      @student).update?
  end

  test "admin viewing their own profile is allowed" do
    assert ProfilePolicy.new(@admin, @admin).show?
  end
end
