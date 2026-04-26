require "test_helper"

class HomologationRequestPolicyTest < ActiveSupport::TestCase
  setup do
    @admin   = users(:admin)
    @student = users(:student_es)
    @other   = users(:student_other)
    @owned   = homologation_requests(:in_pipeline_es)
  end

  test "show? is true for super_admin viewing any request" do
    assert HomologationRequestPolicy.new(@admin, @owned).show?
  end

  test "show? is true for the student who owns the request" do
    assert HomologationRequestPolicy.new(@student, @owned).show?
  end

  test "show? is false for a different student" do
    refute HomologationRequestPolicy.new(@other, @owned).show?
  end

  test "show? is false when user is nil" do
    refute HomologationRequestPolicy.new(nil, @owned).show?
  end

  test "manage_pipeline? is true only for super_admin" do
    assert HomologationRequestPolicy.new(@admin,   @owned).manage_pipeline?
    refute HomologationRequestPolicy.new(@student, @owned).manage_pipeline?
    refute HomologationRequestPolicy.new(nil,      @owned).manage_pipeline?
  end

  test "Scope#resolve returns all requests for super_admin" do
    resolved = HomologationRequestPolicy::Scope.new(@admin, HomologationRequest.all).resolve

    assert_equal HomologationRequest.count, resolved.count
  end

  test "Scope#resolve returns only own requests for a student" do
    resolved = HomologationRequestPolicy::Scope.new(@student, HomologationRequest.all).resolve

    assert_equal @student.homologation_requests.pluck(:id).sort, resolved.pluck(:id).sort
    refute_includes resolved, homologation_requests(:at_redsara_other)
  end

  test "Scope#resolve returns nothing for a nil user" do
    resolved = HomologationRequestPolicy::Scope.new(nil, HomologationRequest.all).resolve

    assert_empty resolved
  end
end
