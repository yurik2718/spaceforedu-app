class HomologationRequestCheckoutsController < ApplicationController
  def create
    hr = HomologationRequest.kept.find(params[:homologation_request_id])
    authorize hr, :checkout?

    session = Stripe::Checkout::Session.create(
      payment_method_types: ["card"],
      line_items: [{
        price_data: {
          currency: "eur",
          unit_amount: (hr.payment_amount * 100).to_i,
          product_data: { name: hr.subject }
        },
        quantity: 1
      }],
      mode: "payment",
      payment_intent_data: { metadata: { homologation_request_id: hr.id } },
      success_url: homologation_request_url(hr, payment: "success"),
      cancel_url:  homologation_request_url(hr)
    )

    hr.update_column(:stripe_payment_intent_id, session.payment_intent)
    redirect_to session.url, allow_other_host: true, status: :see_other
  end
end
