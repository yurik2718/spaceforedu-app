class NotificationJob < ApplicationJob
  queue_as :default

  def perform(notification)
    return if notification.emailed_at.present?

    if notification.user.notification_email?
      NotificationMailer.new_event(notification).deliver_now
      notification.update!(emailed_at: Time.current)
    end

    Turbo::StreamsChannel.broadcast_replace_to(
      notification.user,
      target:  "notifications_bell",
      partial: "shared/notifications_bell",
      locals:  { user: notification.user }
    )
  end
end
