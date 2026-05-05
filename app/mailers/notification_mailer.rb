class NotificationMailer < ApplicationMailer
  def new_event(notification)
    @notification = notification
    @user         = notification.user

    I18n.with_locale(@user.locale) do
      mail to: @user.email_address, subject: notification.title
    end
  end
end
