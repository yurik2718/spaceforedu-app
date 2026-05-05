class HomologationRequestDocumentsController < ApplicationController
  before_action :set_request

  def create
    authorize @homologation_request, :update?
    guard_editable!

    files = Array(params[:files]).reject(&:blank?)
    if files.empty?
      redirect_to @homologation_request, alert: t("flash.no_files_selected") and return
    end

    before_ids = @homologation_request.documents.attachments.pluck(:id)
    files.each { |f| @homologation_request.documents.attach(f) }

    if @homologation_request.valid?
      redirect_to @homologation_request, notice: t("flash.documents_uploaded", count: files.size)
    else
      @homologation_request.documents.attachments
        .reject { |a| before_ids.include?(a.id) }
        .each(&:purge)
      render "homologation_requests/show", status: :unprocessable_entity
    end
  end

  def destroy
    authorize @homologation_request, :update?
    guard_editable!

    attachment = @homologation_request.documents.attachments.find(params[:id])
    attachment.purge_later
    redirect_to @homologation_request, notice: t("flash.document_removed")
  end

  private
    def set_request
      @homologation_request = HomologationRequest.kept
        .includes(:conversation, :user)
        .find(params[:homologation_request_id])
    end

    def guard_editable!
      return if HomologationRequestsController::EDITABLE_STATUSES.include?(@homologation_request.status)
      redirect_to @homologation_request, alert: t("flash.request_not_editable") and return
    end
end
