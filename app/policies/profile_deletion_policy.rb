class ProfileDeletionPolicy < ApplicationPolicy
  def create? = user.present? && user.student?
end
