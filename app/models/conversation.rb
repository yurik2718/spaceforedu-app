class Conversation < ApplicationRecord
  belongs_to :homologation_request, strict_loading: false
  has_many   :messages, dependent: :destroy

  def student
    homologation_request.user
  end

  def unread_for?(user)
    last_read = user.super_admin? ? admin_last_read_at : student_last_read_at
    messages.where("created_at > ?", last_read || Time.at(0)).exists?
  end

  def mark_read_for!(user)
    if user.super_admin?
      update!(admin_last_read_at: Time.current)
    else
      update!(student_last_read_at: Time.current)
    end
  end
end
