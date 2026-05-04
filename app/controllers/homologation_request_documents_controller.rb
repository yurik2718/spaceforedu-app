class HomologationRequestDocumentsController < ApplicationController
  before_action :set_request

  def create
    authorize @homologation_request, :update?
    guard_editable!

    files = Array(params[:files]).reject(&:blank?)
    if files.empty?
      redirect_to @homologation_request, alert: t("flash.no_files_selected") and return
    end

    files.each { |f| @homologation_request.documents.attach(f) }
    redirect_to @homologation_request, notice: t("flash.documents_uploaded", count: files.size)
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
      @homologation_request = HomologationRequest.kept.find(params[:homologation_request_id])
    end

    def guard_editable!
      return if HomologationRequestsController::EDITABLE_STATUSES.include?(@homologation_request.status)
      redirect_to @homologation_request, alert: t("flash.request_not_editable") and return
    end
end
