class HomologationRequest < ApplicationRecord
  belongs_to :user
  belongs_to :status_changer,    class_name: "User", optional: true, foreign_key: :status_changed_by
  belongs_to :payment_confirmer, class_name: "User", optional: true, foreign_key: :payment_confirmed_by
  has_one    :conversation, dependent: :destroy

  has_one_attached  :application_file
  has_many_attached :originals
  has_many_attached :documents

  scope :kept, -> { where(discarded_at: nil) }

  STATUSES = %w[
    draft submitted in_review awaiting_reply
    awaiting_payment payment_confirmed in_progress
    resolved closed
  ].freeze

  def transition_to!(new_status, changed_by:)
    unless STATUSES.include?(new_status.to_s)
      raise InvalidTransition, "Unknown status: #{new_status}"
    end

    update!(
      status:            new_status.to_s,
      status_changed_at: Time.current,
      status_changed_by: changed_by.id
    )
  end

  def confirm_payment!(confirmed_by:)
    update!(
      payment_confirmed_at: Time.current,
      payment_confirmed_by: confirmed_by.id
    )
    transition_to!("payment_confirmed", changed_by: confirmed_by)
  end

  class InvalidTransition < StandardError; end
end
