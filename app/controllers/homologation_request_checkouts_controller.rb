class HomologationRequestCheckoutsController < ApplicationController
  def create
    hr = HomologationRequest.kept.find(params[:homologation_request_id])
    authorize hr, :checkout?

    session = hr.start_checkout!(
      success_url: homologation_request_url(hr, payment: "success"),
      cancel_url:  homologation_request_url(hr)
    )
    redirect_to session.url, allow_other_host: true, status: :see_other
  end
end
