class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read_at: nil) }

  after_create_commit -> { broadcast_prepend_to user, target: "notifications" }

  def mark_read!
    update_column(:read_at, Time.current) unless read_at?
  end
end
