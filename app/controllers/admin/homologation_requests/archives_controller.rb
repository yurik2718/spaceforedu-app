class Admin::HomologationRequests::ArchivesController < ApplicationController
  def show
    request_record = HomologationRequest.kept.find(params[:homologation_request_id])
    authorize request_record, :manage_pipeline?

    send_data request_record.zip_archive,
              type:        "application/zip",
              filename:    request_record.zip_filename,
              disposition: "attachment"
  end
end
