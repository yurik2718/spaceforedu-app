class Admin::HomologationRequests::PaymentConfirmationsController < ApplicationController
  def create
    request_record = HomologationRequest.kept.includes(:user).find(params[:homologation_request_id])
    authorize request_record, :manage_pipeline?

    if confirmation_params[:payment_amount].present?
      request_record.update!(payment_amount: confirmation_params[:payment_amount])
    end

    request_record.confirm_payment!(confirmed_by: Current.user)
    redirect_to admin_homologation_request_path(request_record), notice: t("flash.payment_confirmed")
  end

  private
    def confirmation_params
      params.fetch(:payment_confirmation, {}).permit(:payment_amount)
    end
end
