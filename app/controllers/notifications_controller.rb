class NotificationsController < ApplicationController
  before_action :set_notification, only: :show

  def index
    scope = policy_scope(Notification).includes(:user).order(Arel.sql("read_at IS NULL DESC, created_at DESC"))
    @pagy, notifications = pagy(scope, limit: 25)
    @groups = notifications.chunk_while { |a, b| a.group_key == b.group_key }.to_a
    @unread_count = policy_scope(Notification).unread.count
  end

  def show
    @notification.mark_read!
    redirect_to polymorphic_path(@notification.notifiable)
  end

  def read_all
    authorize Notification
    policy_scope(Notification).unread.update_all(read_at: Time.current)
    redirect_to notifications_path
  end

  private
    def set_notification
      @notification = policy_scope(Notification).includes(:notifiable).find(params[:id])
      authorize @notification
    end
end
