require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:student_es)
    @unread  = notifications(:unread_status_change)
    @already = notifications(:already_read_message)
  end

  test "GET index renders notifications for the user" do
    sign_in_as @student
    get notifications_path

    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(@unread)}"
    assert_select "##{ActionView::RecordIdentifier.dom_id(@already)}"
  end

  test "GET index does not mark unread notifications as read" do
    sign_in_as @student

    assert_nil @unread.read_at
    get notifications_path
    assert_nil @unread.reload.read_at
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

  test "GET index renders the mark-all-read button only when there are unread notifications" do
    sign_in_as @student
    get notifications_path
    assert_select "form[action='#{read_all_notifications_path}']"

    @unread.mark_read!
    get notifications_path
    assert_select "form[action='#{read_all_notifications_path}']", count: 0
  end

  test "GET index collapses adjacent identical notifications into a single grouped card" do
    sign_in_as @student
    siblings = 3.times.map do
      @student.notifications.create!(
        notifiable: @unread.notifiable,
        title:      @unread.title,
        title_key:  @unread.title_key,
      )
    end

    get notifications_path
    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(siblings.last)}"
    siblings[0..-2].each do |hidden|
      assert_select "##{ActionView::RecordIdentifier.dom_id(hidden)}", count: 0
    end
  end

  test "GET show marks the notification read and redirects to the notifiable" do
    sign_in_as @student

    get notification_path(@unread)

    assert_redirected_to polymorphic_path(@unread.notifiable)
    assert_not_nil @unread.reload.read_at
  end

  test "GET show is a no-op for already-read notifications and still redirects" do
    sign_in_as @student
    original = @already.read_at

    get notification_path(@already)

    assert_redirected_to polymorphic_path(@already.notifiable)
    assert_equal original.to_i, @already.reload.read_at.to_i
  end

  test "GET show 404s when the notification belongs to another user" do
    sign_in_as users(:student_other)
    get notification_path(@unread)
    assert_response :not_found
  end

  test "POST read_all clears every unread notification for the current user" do
    sign_in_as @student
    assert_nil @unread.read_at

    post read_all_notifications_path

    assert_redirected_to notifications_path
    assert_not_nil @unread.reload.read_at
  end

  test "POST read_all does not touch other users' notifications" do
    sign_in_as users(:student_other)

    post read_all_notifications_path

    assert_nil @unread.reload.read_at
  end
end
