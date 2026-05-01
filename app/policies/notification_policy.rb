class NotificationPolicy < ApplicationPolicy
  def show? = user.present? && record.user_id == user.id

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.nil?
      scope.where(user_id: user.id)
    end
  end
end
