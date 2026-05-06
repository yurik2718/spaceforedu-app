require "test_helper"

module Stripe
  class WebhooksControllerTest < ActionDispatch::IntegrationTest
    def post_signed_event(payload)
      timestamp = Time.now.to_i
      secret    = Rails.application.credentials.dig(:stripe, :webhook_secret)
      signature = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{payload}")

      post "/stripe/webhooks",
           params: payload,
           headers: {
             "CONTENT_TYPE"     => "application/json",
             "Stripe-Signature" => "t=#{timestamp},v1=#{signature}"
           }
    end

    test "POST without a Stripe-Signature header returns 400" do
      post "/stripe/webhooks",
           params: '{"id":"evt_test","type":"payment_intent.succeeded"}',
           headers: { "CONTENT_TYPE" => "application/json" }

      assert_response :bad_request
    end

    test "POST with an invalid Stripe-Signature returns 400" do
      post "/stripe/webhooks",
           params: '{"id":"evt_test","type":"payment_intent.succeeded"}',
           headers: {
             "CONTENT_TYPE"     => "application/json",
             "Stripe-Signature" => "t=123,v1=not_a_real_signature"
           }

      assert_response :bad_request
    end

    test "POST with a valid signature returns 200 for an event we do not specifically handle" do
      post_signed_event '{"id":"evt_unhandled","type":"customer.created","data":{"object":{}}}'

      assert_response :ok
    end

    test "payment_intent.succeeded confirms payment on the matching request" do
      request = homologation_requests(:awaiting_payment)
      payload = {
        id:   "evt_pi_succeeded_1",
        type: "payment_intent.succeeded",
        data: { object: { id: request.stripe_payment_intent_id } }
      }.to_json

      post_signed_event payload

      assert_response :ok
      assert_equal "payment_confirmed", request.reload.status
      assert_not_nil request.payment_confirmed_at
    end

    test "payment_intent.succeeded notifies the super admin that the payment arrived" do
      request = homologation_requests(:awaiting_payment)
      admin   = users(:admin)
      payload = {
        id:   "evt_pi_succeeded_admin_notif",
        type: "payment_intent.succeeded",
        data: { object: { id: request.stripe_payment_intent_id } }
      }.to_json

      assert_difference -> {
        admin.notifications.where(notifiable: request, title_key: "notifications.payment_received.title").count
      }, 1 do
        post_signed_event payload
      end
    end

    test "payment_intent.payment_failed notifies the super admin" do
      request = homologation_requests(:awaiting_payment)
      admin   = users(:admin)
      payload = {
        id:   "evt_pi_failed_1",
        type: "payment_intent.payment_failed",
        data: { object: { id: request.stripe_payment_intent_id } }
      }.to_json

      assert_difference -> { admin.notifications.where(notifiable: request).count }, 1 do
        post_signed_event payload
      end

      assert_response :ok
      assert_equal "awaiting_payment", request.reload.status
    end

    test "payment_intent.succeeded for an unknown intent id returns 200 without crashing" do
      payload = {
        id:   "evt_pi_unknown",
        type: "payment_intent.succeeded",
        data: { object: { id: "pi_does_not_exist_anywhere" } }
      }.to_json

      post_signed_event payload

      assert_response :ok
    end

    test "redelivered event with the same id is a no-op" do
      request = homologation_requests(:awaiting_payment)
      payload = {
        id:   "evt_pi_succeeded_dup",
        type: "payment_intent.succeeded",
        data: { object: { id: request.stripe_payment_intent_id } }
      }.to_json

      post_signed_event payload
      assert_response :ok
      first_confirmed_at = request.reload.payment_confirmed_at

      travel 5.minutes do
        post_signed_event payload
      end

      assert_response :ok
      assert_equal first_confirmed_at, request.reload.payment_confirmed_at,
                   "duplicate event must not overwrite payment_confirmed_at"
    end
  end
end
