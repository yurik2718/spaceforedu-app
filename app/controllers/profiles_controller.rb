class ProfilesController < ApplicationController
  def show
    @user = Current.user
    authorize @user, policy_class: ProfilePolicy
  end

  def edit
    @user = Current.user
    authorize @user, policy_class: ProfilePolicy
  end

  def update
    @user = Current.user
    authorize @user, policy_class: ProfilePolicy

    if @user.update(profile_params)
      redirect_to profile_path, notice: t("flash.user_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def profile_params
      params.expect(user: %i[
        name country locale phone whatsapp
        notification_email notification_telegram
        guardian_name guardian_email guardian_phone
      ])
    end
end
