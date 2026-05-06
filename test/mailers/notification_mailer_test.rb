require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers
  default_url_options[:host] = "example.com"

  test "new_event addresses the notification's user with the title as subject and body in the email" do
    notification = notifications(:unread_status_change)

    mail = NotificationMailer.new_event(notification)

    assert_equal [ notification.user.email_address ], mail.to
    assert_equal notification.title,                  mail.subject
    assert_includes mail.body.encoded, notification.body
  end

  test "new_event body deep-links to the notifiable record, not the homepage" do
    notification = notifications(:unread_status_change)
    request      = notification.notifiable

    mail = NotificationMailer.new_event(notification)

    assert_includes mail.html_part.body.encoded, homologation_request_url(request)
    assert_includes mail.text_part.body.encoded, homologation_request_url(request)
  end
end
