class NotificationJob < ApplicationJob
  include Rails.application.routes.url_helpers

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

    send_push(notification)
  end

  private
    def send_push(notification)
      subscriptions = notification.user.push_subscriptions
      return if subscriptions.empty?

      vapid = Rails.application.credentials.vapid
      return unless vapid&.dig(:public_key) && vapid&.dig(:private_key)

      payload = JSON.generate({
        title:   notification.title,
        options: {
          body: notification.body,
          icon: "/icon.png",
          data: { path: notifiable_path(notification.notifiable) }
        }
      })

      subscriptions.each do |sub|
        WebPush.payload_send(
          message:  payload,
          endpoint: sub.endpoint,
          p256dh:   sub.p256dh_key,
          auth:     sub.auth_key,
          vapid:    { subject: "mailto:#{Rails.application.config.action_mailer.default_options&.dig(:from) || "noreply@spaceforedu.com"}",
                      public_key:  vapid[:public_key],
                      private_key: vapid[:private_key] }
        )
      rescue WebPush::InvalidSubscription, WebPush::ExpiredSubscription
        sub.destroy
      end
    end

    def notifiable_path(notifiable)
      case notifiable
      when HomologationRequest then homologation_request_path(notifiable)
      when Conversation        then conversation_path(notifiable)
      else notifications_path
      end
    end
end
