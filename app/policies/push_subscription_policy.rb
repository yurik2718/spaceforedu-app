class PushSubscriptionPolicy < ApplicationPolicy
  def create?  = true
  def destroy? = true
end
