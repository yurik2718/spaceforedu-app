require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  setup do
    @policy = ApplicationPolicy.new(users(:admin), Object.new)
  end

  test "all action predicates default to false" do
    refute @policy.index?
    refute @policy.show?
    refute @policy.create?
    refute @policy.new?
    refute @policy.update?
    refute @policy.edit?
    refute @policy.destroy?
  end

  test "new? delegates to create?" do
    policy = ApplicationPolicy.new(nil, nil)
    policy.define_singleton_method(:create?) { true }

    assert policy.new?
  end

  test "edit? delegates to update?" do
    policy = ApplicationPolicy.new(nil, nil)
    policy.define_singleton_method(:update?) { true }

    assert policy.edit?
  end

  test "Scope#resolve raises NotImplementedError" do
    scope = ApplicationPolicy::Scope.new(users(:admin), HomologationRequest.all)

    assert_raises(NotImplementedError) { scope.resolve }
  end
end
