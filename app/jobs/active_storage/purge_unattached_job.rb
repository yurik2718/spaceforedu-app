class ActiveStorage::PurgeUnattachedJob < ApplicationJob
  queue_as :default

  THRESHOLD = 24.hours

  def perform
    ActiveStorage::Blob.unattached
      .where("active_storage_blobs.created_at < ?", THRESHOLD.ago)
      .find_each do |blob|
        blob.strict_loading!(false)
        blob.purge
      end
  end
end
