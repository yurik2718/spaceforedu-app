class NotificationsController < ApplicationController
  def index
    scope = policy_scope(Notification).order(Arel.sql("read_at IS NULL DESC, created_at DESC"))
    @pagy, @notifications = pagy(scope, limit: 25)

    @notifications.each { |n| n.mark_read! if n.read_at.nil? }
  end
end
