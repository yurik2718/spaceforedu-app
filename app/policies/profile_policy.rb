class ProfilePolicy < ApplicationPolicy
  def show?    = user.present? && record == user
  def update?  = show?
  def export?  = show?
end
