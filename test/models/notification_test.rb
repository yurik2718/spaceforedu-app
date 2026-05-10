require "test_helper"
require "turbo/broadcastable/test_helper"

class NotificationTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper
  include ActiveJob::TestHelper

  setup do
    @student = users(:student_es)
    @request = homologation_requests(:in_pipeline_es)
  end

  test "unread scope returns only notifications without read_at" do
    unread = notifications(:unread_status_change)

    assert_includes     Notification.unread, unread
    assert_not_includes Notification.unread, notifications(:already_read_message)
  end

  test "mark_read! sets read_at to the current time" do
    notification = notifications(:unread_status_change)

    freeze_time do
      notification.mark_read!
      assert_equal Time.current, notification.reload.read_at
    end
  end

  test "mark_read! is a no-op when already read" do
    notification = notifications(:already_read_message)
    original     = notification.read_at

    notification.mark_read!

    assert_equal original, notification.reload.read_at
  end

  test "after_create_commit broadcasts a prepend to the user notifications stream" do
    assert_turbo_stream_broadcasts(@student, count: 1) do
      @student.notifications.create!(notifiable: @request, title: "Hi")
    end
  end

  test "title resolves at render time from title_key + i18n_vars in the user's current locale" do
    @student.update!(locale: "es")
    notification = @student.notify(
      notifiable: @request,
      title_key:  "notifications.payment_confirmed.title",
      body_key:   "notifications.payment_confirmed.body",
      subject:    "Mi diploma"
    )

    assert_equal I18n.t("notifications.payment_confirmed.title", subject: "Mi diploma", locale: "es"), notification.title

    @student.update!(locale: "en")
    assert_equal I18n.t("notifications.payment_confirmed.title", subject: "Mi diploma", locale: "en"), notification.reload.title
  end

  test "after_create_commit enqueues a NotificationJob to deliver email" do
    assert_enqueued_with(job: NotificationJob) do
      @student.notifications.create!(notifiable: @request, title: "Hi")
    end
  end

  test "group_key is identical for same notifiable + title_key and differs otherwise" do
    a = @student.notifications.create!(notifiable: @request, title_key: "notifications.new_message.title")
    b = @student.notifications.create!(notifiable: @request, title_key: "notifications.new_message.title")
    c = @student.notifications.create!(notifiable: @request, title_key: "notifications.status_changed.title")

    assert_equal     a.group_key, b.group_key
    assert_not_equal a.group_key, c.group_key
  end
end
