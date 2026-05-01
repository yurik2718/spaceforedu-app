require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student   = users(:student_es)
    @unread    = notifications(:unread_status_change)
    @already   = notifications(:already_read_message)
  end

  test "GET index renders notifications for the user" do
    sign_in_as @student
    get notifications_path

    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(@unread)}"
    assert_select "##{ActionView::RecordIdentifier.dom_id(@already)}"
  end

  test "GET index marks unread notifications as read" do
    sign_in_as @student

    assert_nil @unread.read_at
    get notifications_path
    assert_not_nil @unread.reload.read_at
  end

  test "GET index does not change read_at on already-read notifications" do
    sign_in_as @student
    original = @already.read_at
    get notifications_path
    assert_equal original.to_i, @already.reload.read_at.to_i
  end

  test "GET index redirects unauthenticated visitors to sign in" do
    get notifications_path
    assert_redirected_to new_session_path
  end

  test "GET index does not show another user's notifications" do
    sign_in_as users(:student_other)
    get notifications_path
    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(@unread)}", count: 0
  end
end
