class SessionCleanupJob < ApplicationJob
  queue_as :default

  # Sessions older than 90 days are considered expired (matches cookie lifetime)
  RETENTION_PERIOD = 90.days

  def perform
    cutoff = RETENTION_PERIOD.ago
    deleted = Session.where("updated_at < ?", cutoff).delete_all
    Rails.logger.info "[SessionCleanupJob] Deleted #{deleted} sessions older than #{cutoff.to_date}"
  end
end
