require "test_helper"

class NotificationPolicyTest < ActiveSupport::TestCase
  setup do
    @student = users(:student_es)
    @other   = users(:student_other)
    @admin   = users(:admin)
    @owned   = notifications(:unread_status_change)
  end

  test "Scope#resolve returns only notifications belonging to the user" do
    resolved = NotificationPolicy::Scope.new(@student, Notification.all).resolve
    assert_equal @student.notifications.pluck(:id).sort, resolved.pluck(:id).sort
  end

  test "Scope#resolve returns nothing for nil user" do
    resolved = NotificationPolicy::Scope.new(nil, Notification.all).resolve
    assert_empty resolved
  end

  test "Scope#resolve returns only admin's own notifications" do
    resolved = NotificationPolicy::Scope.new(@admin, Notification.all).resolve
    assert_equal @admin.notifications.pluck(:id).sort, resolved.pluck(:id).sort
  end

  test "show? is true for the owner only" do
    assert NotificationPolicy.new(@student, @owned).show?
    refute NotificationPolicy.new(@other,   @owned).show?
    refute NotificationPolicy.new(nil,      @owned).show?
  end
end
