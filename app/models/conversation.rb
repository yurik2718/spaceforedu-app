class Conversation < ApplicationRecord
  belongs_to :homologation_request
  has_many   :messages, dependent: :destroy

  def student
    homologation_request.user
  end

  def unread_for?(user)
    return false unless messages.exists?
    last_read = user.super_admin? ? admin_last_read_at : student_last_read_at
    last_read.nil? || messages.where("created_at > ?", last_read).exists?
  end

  def mark_read_for!(user)
    if user.super_admin?
      update_column(:admin_last_read_at, Time.current)
    else
      update_column(:student_last_read_at, Time.current)
    end
  end
end
