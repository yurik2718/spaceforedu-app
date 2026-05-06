class HomologationRequestSubmissionsController < ApplicationController
  def create
    homologation_request = HomologationRequest.kept
      .includes(:user)
      .with_attached_application_file
      .with_attached_documents
      .find(params[:homologation_request_id])
    authorize homologation_request, :submit?

    unless homologation_request.status == "draft"
      redirect_to homologation_request, alert: t("flash.request_not_submittable") and return
    end

    homologation_request.transition_to!("submitted", changed_by: Current.user)
    notify_admin_of_submission(homologation_request)
    redirect_to homologation_request, notice: t("flash.request_submitted")
  rescue HomologationRequest::InvalidTransition
    redirect_to homologation_request, alert: t("flash.request_not_submittable")
  end

  private
    def notify_admin_of_submission(hr)
      admin = User.super_admin
      return unless admin

      admin.notify(
        notifiable: hr,
        title_key:  "notifications.request_submitted.title",
        body_key:   "notifications.request_submitted.body",
        subject:    hr.subject,
        student:    hr.user.name
      )
    end
end
