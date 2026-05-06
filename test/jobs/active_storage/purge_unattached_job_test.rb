require "test_helper"

class ActiveStorage::PurgeUnattachedJobTest < ActiveJob::TestCase
  test "purges unattached blobs older than the configured threshold" do
    stale = ActiveStorage::Blob.create_and_upload!(
      io:           StringIO.new("stale"),
      filename:     "stale.pdf",
      content_type: "application/pdf"
    )
    stale.update_columns(created_at: 25.hours.ago)

    fresh = ActiveStorage::Blob.create_and_upload!(
      io:           StringIO.new("fresh"),
      filename:     "fresh.pdf",
      content_type: "application/pdf"
    )

    ActiveStorage::PurgeUnattachedJob.perform_now

    assert_not ActiveStorage::Blob.exists?(stale.id), "expected stale unattached blob to be purged"
    assert     ActiveStorage::Blob.exists?(fresh.id), "expected fresh unattached blob to survive"
  end
end
