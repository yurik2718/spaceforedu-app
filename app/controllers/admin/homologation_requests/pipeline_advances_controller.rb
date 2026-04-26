class Admin::HomologationRequests::PipelineAdvancesController < ApplicationController
  def create
    request_record = HomologationRequest.kept.find(params[:homologation_request_id])
    authorize request_record, :manage_pipeline?

    request_record.advance_pipeline!(changed_by: Current.user)
    redirect_to admin_pipeline_path, notice: t("flash.pipeline_advanced")
  rescue HomologationRequest::InvalidTransition => e
    redirect_to admin_pipeline_path, alert: e.message
  end
end
