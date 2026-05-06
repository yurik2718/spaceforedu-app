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
      notify_admin_of_reply(files.size) if @homologation_request.status == "awaiting_reply"
      redirect_to @homologation_request, notice: t("flash.documents_uploaded", count: files.size)
    else
      new_blob_ids = new_blobs.map(&:id)
      @homologation_request.documents.attachments.select { |a| new_blob_ids.include?(a.blob_id) }.each(&:purge_later)

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
      return if HomologationRequestsController::EDITABLE_STATUSES.include?(@homologation_request.status)
      redirect_to @homologation_request, alert: t("flash.request_not_editable") and return
    end

    def notify_admin_of_reply(file_count)
      admin = User.super_admin
      return unless admin

      admin.notify(
        notifiable: @homologation_request,
        title_key:  "notifications.documents_added.title",
        body_key:   "notifications.documents_added.body",
        subject:    @homologation_request.subject,
        student:    @homologation_request.user.name,
        count:      file_count
      )
    end
end
