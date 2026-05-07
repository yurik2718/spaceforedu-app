class NotificationsController < ApplicationController
  def index
    scope = policy_scope(Notification).order(Arel.sql("read_at IS NULL DESC, created_at DESC"))
    @pagy, @notifications = pagy(scope, limit: 25)

    unread_ids = @notifications.filter_map { |n| n.id if n.read_at.nil? }
    Notification.where(id: unread_ids).update_all(read_at: Time.current) if unread_ids.any?
  end
end
