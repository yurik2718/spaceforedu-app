class PipelinePolicy < ApplicationPolicy
  def show? = user&.super_admin?
end
