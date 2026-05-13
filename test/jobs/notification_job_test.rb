require "test_helper"
require "turbo/broadcastable/test_helper"

class NotificationJobTest < ActiveJob::TestCase
  include Turbo::Broadcastable::TestHelper

  test "perform delivers the email and stamps emailed_at on the notification" do
    notification = notifications(:unread_status_change)

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      freeze_time do
        NotificationJob.perform_now(notification)

        assert_equal Time.current, notification.reload.emailed_at
      end
    end
  end

  test "perform skips delivery and emailed_at when the user has email notifications off" do
    notification = notifications(:unread_status_change)
    notification.user.update!(notification_email: false)

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      NotificationJob.perform_now(notification)
    end

    assert_nil notification.reload.emailed_at
  end

  test "perform is idempotent: a notification already emailed is not re-sent" do
    notification = notifications(:unread_status_change)
    notification.update!(emailed_at: 1.hour.ago)

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      NotificationJob.perform_now(notification)
    end
  end

  test "perform broadcasts a replace of the notifications_bell partial to the recipient" do
    notification = notifications(:unread_status_change)

    assert_turbo_stream_broadcasts(notification.user, count: 1) do
      NotificationJob.perform_now(notification)
    end
  end
end
