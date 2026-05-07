class StripeEventCleanupJob < ApplicationJob
  queue_as :default

  # Keep Stripe events for 13 months (Stripe's own recommendation for dispute resolution)
  RETENTION_PERIOD = 13.months

  def perform
    cutoff = RETENTION_PERIOD.ago
    deleted = StripeEvent.where("received_at < ?", cutoff).delete_all
    Rails.logger.info "[StripeEventCleanupJob] Deleted #{deleted} Stripe events older than #{cutoff.to_date}"
  end
end
