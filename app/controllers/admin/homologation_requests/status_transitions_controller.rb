class Admin::HomologationRequests::StatusTransitionsController < ApplicationController
  def create
    request_record = HomologationRequest.kept.includes(:user).find(params[:homologation_request_id])
    authorize request_record, :manage_pipeline?

    request_record.transition_to!(transition_params[:status], changed_by: Current.user)
    redirect_to admin_homologation_request_path(request_record), notice: t("flash.status_changed")
  rescue ActionController::ParameterMissing, HomologationRequest::InvalidTransition => e
    redirect_to admin_homologation_request_path(request_record), alert: e.message
  end

  private
    def transition_params
      params.expect(status_transition: [:status])
    end
end
