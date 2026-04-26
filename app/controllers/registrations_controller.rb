class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  skip_after_action :verify_authorized
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_registration_path, alert: t("errors.rate_limited") }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    unless privacy_accepted?
      @user.errors.add(:privacy_accepted, :acceptance, message: t("errors.privacy_required"))
      return render :new, status: :unprocessable_entity
    end

    @user.privacy_accepted_at = Time.current

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: t("flash.registered")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.expect(user: %i[email_address password password_confirmation name])
    end

    def privacy_accepted?
      params.dig(:user, :privacy_accepted) == "1"
    end
end
