require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  test "new_event addresses the notification's user with the title as subject and body in the email" do
    notification = notifications(:unread_status_change)

    mail = NotificationMailer.new_event(notification)

    assert_equal [ notification.user.email_address ], mail.to
    assert_equal notification.title,                  mail.subject
    assert_includes mail.body.encoded, notification.body
  end
end
