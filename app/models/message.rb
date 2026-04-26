class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  has_many_attached :attachments

  after_create_commit -> { broadcast_append_to conversation }
  after_create_commit :touch_conversation

  private
    def touch_conversation
      conversation.update_column(:last_message_at, created_at)
    end
end
