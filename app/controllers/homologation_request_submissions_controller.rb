class HomologationRequestSubmissionsController < ApplicationController
  # Used for two symmetric "I'm done, your turn" handoffs:
  #   draft          → submitted   (first delivery)
  #   awaiting_reply → in_review   (reply delivery)
  # Both flip status, both notify the admin. The student-facing button looks
  # identical; only the label changes.
  def create
    homologation_request = HomologationRequest.kept
      .includes(:user, :request_documents)
      .find(params[:homologation_request_id])
    authorize homologation_request, :submit?

    case homologation_request.status
    when "draft"
      homologation_request.transition_to!("submitted", changed_by: Current.user)
      redirect_to homologation_request, notice: t("flash.request_submitted")
    when "awaiting_reply"
      homologation_request.transition_to!("in_review", changed_by: Current.user)
      redirect_to homologation_request, notice: t("flash.reply_sent")
    else
      redirect_to homologation_request, alert: t("flash.request_not_submittable")
    end
  rescue HomologationRequest::InvalidTransition
    redirect_to homologation_request, alert: t("flash.request_not_submittable")
  end
end
