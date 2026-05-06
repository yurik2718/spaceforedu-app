class HomologationRequestSubmissionsController < ApplicationController
  def create
    homologation_request = HomologationRequest.kept
      .with_attached_application_file
      .with_attached_documents
      .find(params[:homologation_request_id])
    authorize homologation_request, :submit?

    unless homologation_request.status == "draft"
      redirect_to homologation_request, alert: t("flash.request_not_submittable") and return
    end

    homologation_request.transition_to!("submitted", changed_by: Current.user)
    redirect_to homologation_request, notice: t("flash.request_submitted")
  rescue HomologationRequest::InvalidTransition
    redirect_to homologation_request, alert: t("flash.request_not_submittable")
  end
end
