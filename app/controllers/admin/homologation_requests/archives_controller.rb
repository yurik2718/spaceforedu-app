class Admin::HomologationRequests::ArchivesController < ApplicationController
  def show
    request_record = HomologationRequest.kept.includes(:user).find(params[:homologation_request_id])
    authorize request_record, :manage_pipeline?

    archive = RequestArchive.new(request_record)
    send_data archive.zip_body,
              type:        "application/zip",
              filename:    archive.filename,
              disposition: "attachment"
  end
end
