class HomologationRequestDocumentsController < ApplicationController
  before_action :set_request

  def create
    authorize @homologation_request, :update?
    guard_editable!

    files = Array(params[:files]).reject(&:blank?)
    if files.empty?
      redirect_to @homologation_request, alert: t("flash.no_files_selected") and return
    end

    new_blobs = files.map do |f|
      ActiveStorage::Blob.create_and_upload!(io: f, filename: f.original_filename, content_type: f.content_type)
    end
    new_blobs.each { |blob| @homologation_request.documents.attach(blob) }

    if @homologation_request.valid?
      @homologation_request.notify_admin_of_documents_reply!(count: files.size)
      redirect_to @homologation_request, notice: t("flash.documents_uploaded", count: files.size)
    else
      new_blob_ids = new_blobs.map(&:id)
      @homologation_request.documents.attachments.select { |a| new_blob_ids.include?(a.blob_id) }.each(&:purge_later)

      @checklist_keys = PipelineFlow.checklist_keys
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            view_context.dom_id(@homologation_request, :documents),
            partial: "homologation_requests/documents",
            locals:  { hr: @homologation_request, can_edit: true }
          ), status: :unprocessable_entity
        end
        format.html { render "homologation_requests/show", status: :unprocessable_entity }
      end
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
      return if @homologation_request.editable?
      redirect_to @homologation_request, alert: t("flash.request_not_editable") and return
    end


end
