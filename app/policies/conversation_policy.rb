class ConversationPolicy < ApplicationPolicy
  def show?
    user&.super_admin? || record.homologation_request.user_id == user&.id
  end
end
