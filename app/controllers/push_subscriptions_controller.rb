class PushSubscriptionsController < ApplicationController
  def create
    authorize PushSubscription
    sub = current_user.push_subscriptions.find_or_initialize_by(endpoint: params[:endpoint])
    sub.update!(p256dh_key: params[:p256dh_key], auth_key: params[:auth_key])
    head :ok
  end

  def destroy
    authorize PushSubscription
    current_user.push_subscriptions.find_by(endpoint: params[:endpoint])&.destroy
    head :ok
  end
end
