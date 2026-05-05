class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  has_many_attached :attachments

  validates :body, presence: true

  after_create        :auto_advance_request_status
  after_create_commit -> { broadcast_append_to conversation }
  after_create_commit :touch_conversation
  after_create_commit :notify_counterpart

  private
    def touch_conversation
      conversation.update!(last_message_at: created_at)
    end

    def auto_advance_request_status
      request = conversation.homologation_request
      return unless user_id == request.user_id && request.status == "awaiting_reply"

      request.transition_to!("in_review", changed_by: user)
    end

    def notify_counterpart
      recipient = counterpart
      return unless recipient

      recipient.notify(
        notifiable: conversation.homologation_request,
        title_key:  "notifications.new_message.title",
        body_key:   "notifications.new_message.body",
        subject:    conversation.homologation_request.subject,
        sender:     user.name
      )
    end

    def counterpart
      owner = conversation.homologation_request.user
      user == owner ? User.kept.where(role: "super_admin").first : owner
    end
end
