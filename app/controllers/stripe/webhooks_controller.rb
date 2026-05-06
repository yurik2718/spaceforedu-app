module Stripe
  class WebhooksController < ActionController::Base
    def create
      event = ::Stripe::Webhook.construct_event(
        request.body.read,
        request.headers["Stripe-Signature"].to_s,
        Rails.application.credentials.dig(:stripe, :webhook_secret)
      )

      handle(event) if record(event)
      head :ok
    rescue ::Stripe::SignatureVerificationError, JSON::ParserError
      head :bad_request
    end

    private
      def record(event)
        StripeEvent.insert(
          { id: event.id, type: event.type, payload: event.to_json, received_at: Time.current },
          unique_by: :id
        ).any?
      end

      def handle(event)
        case event.type
        when "payment_intent.succeeded"      then confirm_payment(event.data.object.id)
        when "payment_intent.payment_failed" then notify_payment_failed(event.data.object.id)
        end
      end

      def confirm_payment(payment_intent_id)
        request = HomologationRequest.kept.find_by(stripe_payment_intent_id: payment_intent_id)
        return unless request

        request.confirm_payment!(confirmed_by: super_admin)
      end

      def notify_payment_failed(payment_intent_id)
        request = HomologationRequest.kept.find_by(stripe_payment_intent_id: payment_intent_id)
        return unless request

        super_admin.notify(
          notifiable: request,
          title_key:  "notifications.payment_failed.title",
          body_key:   "notifications.payment_failed.body",
          subject:    request.subject
        )
      end

      def super_admin
        User.kept.where(role: "super_admin").order(:id).first
      end
  end
end
