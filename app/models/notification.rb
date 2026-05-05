class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read_at: nil) }

  after_create_commit -> { broadcast_prepend_to user, target: "notifications" }
  after_create_commit -> { NotificationJob.perform_later(self) }

  def mark_read!
    return if read_at?
    update!(read_at: Time.current)
  end
end
