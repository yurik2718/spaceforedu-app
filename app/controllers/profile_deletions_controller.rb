class ProfileDeletionsController < ApplicationController
  def create
    @user = Current.user
    authorize @user, policy_class: ProfileDeletionPolicy

    if @user.deletion_requested_at?
      redirect_to profile_path, alert: t("flash.deletion_already_requested")
    else
      @user.request_deletion!
      redirect_to new_session_path, notice: t("flash.deletion_requested")
    end
  end
end
