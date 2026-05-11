class HomologationRequestSubmissionsController < ApplicationController
  def create
    homologation_request = HomologationRequest.kept
      .includes(:user, :request_documents)
      .find(params[:homologation_request_id])
    authorize homologation_request, :submit?

    homologation_request.transition_to!("submitted", changed_by: Current.user)
    redirect_to homologation_request, notice: t("flash.request_submitted")
  rescue HomologationRequest::InvalidTransition
    redirect_to homologation_request, alert: t("flash.request_not_submittable")
  end
end
