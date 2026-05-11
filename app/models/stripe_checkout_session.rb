class StripeCheckoutSession
  def initialize(request)
    @request = request
  end

  def create(success_url:, cancel_url:)
    plan = @request.plan

    Stripe::Checkout::Session.create(
      payment_method_types: [ "card" ],
      line_items: [ {
        price_data: {
          currency:     "eur",
          unit_amount:  plan.amount * 100,
          product_data: { name: "#{plan.title} — #{@request.subject}" }
        },
        quantity: 1
      } ],
      mode: "payment",
      payment_intent_data: { metadata: { homologation_request_id: @request.id } },
      success_url:,
      cancel_url:
    )
  end
end
