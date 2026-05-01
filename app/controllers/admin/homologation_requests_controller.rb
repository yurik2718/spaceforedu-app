class Admin::HomologationRequestsController < ApplicationController
  def show
    @homologation_request = HomologationRequest.kept
                              .includes(:user, :conversation, :status_changer, :payment_confirmer, :pipeline_changer)
                              .find(params[:id])
    authorize @homologation_request, :manage_pipeline?
  end
end
