class Admin::HomologationRequests::PipelineRetreatsController < ApplicationController
  def create
    request_record = HomologationRequest.kept.includes(:user).find(params[:homologation_request_id])
    authorize request_record, :manage_pipeline?

    request_record.retreat_pipeline!(changed_by: Current.user, reason: retreat_params[:reason])
    redirect_to admin_pipeline_path, notice: t("flash.pipeline_retreated")
  rescue ActionController::ParameterMissing, ArgumentError, HomologationRequest::InvalidTransition => e
    redirect_to admin_pipeline_path, alert: e.message
  end

  private
    def retreat_params
      params.expect(pipeline_retreat: [ :reason ])
    end
end
