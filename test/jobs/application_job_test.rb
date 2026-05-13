require "test_helper"

class ApplicationJobTest < ActiveJob::TestCase
  class FakeJob < ApplicationJob
    def perform(record); end
  end

  test "discards the job if the record was deleted (DeserializationError)" do
    notification = notifications(:unread_status_change)
    FakeJob.perform_later(notification)
    notification.destroy!

    assert_nothing_raised do
      perform_enqueued_jobs
    end
    assert_equal 0, enqueued_jobs.size
  end
end
