class MessagePolicy < ApplicationPolicy
  def create?
    user&.super_admin? || record.conversation.homologation_request.user_id == user&.id
  end
end
