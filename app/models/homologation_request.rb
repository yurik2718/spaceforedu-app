class HomologationRequest < ApplicationRecord
  belongs_to :user
  belongs_to :status_changer,    class_name: "User", optional: true, foreign_key: :status_changed_by
  belongs_to :payment_confirmer, class_name: "User", optional: true, foreign_key: :payment_confirmed_by
  belongs_to :pipeline_changer,  class_name: "User", optional: true, foreign_key: :pipeline_changed_by
  has_one    :conversation, dependent: :destroy

  has_one_attached  :application_file
  has_many_attached :originals
  has_many_attached :documents

  serialize :document_checklist, coder: JSON

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
    transaction do
      update!(
        payment_confirmed_at: Time.current,
        payment_confirmed_by: confirmed_by.id,
        pipeline_stage:       PipelineFlow::STARTING_STAGE,
        pipeline_changed_at:  Time.current,
        pipeline_changed_by:  confirmed_by.id
      )
      transition_to!("payment_confirmed", changed_by: confirmed_by)
    end
  end

  def advance_pipeline!(changed_by:)
    next_stage = PipelineFlow.next_stage(pipeline_stage, country: user.country)
    raise InvalidTransition, "no next pipeline stage from #{pipeline_stage.inspect}" if next_stage.nil?

    update!(
      pipeline_stage:      next_stage,
      pipeline_changed_at: Time.current,
      pipeline_changed_by: changed_by.id
    )
  end

  def retreat_pipeline!(changed_by:, reason:)
    raise ArgumentError, "reason can't be blank" if reason.to_s.strip.empty?

    prev_stage = PipelineFlow.previous_stage(pipeline_stage, country: user.country)
    raise InvalidTransition, "no previous pipeline stage from #{pipeline_stage.inspect}" if prev_stage.nil?

    log_entry = "[#{Time.current.iso8601}] #{changed_by.email_address} #{pipeline_stage} → #{prev_stage}: #{reason.strip}"

    update!(
      pipeline_stage:      prev_stage,
      pipeline_changed_at: Time.current,
      pipeline_changed_by: changed_by.id,
      pipeline_notes:      [pipeline_notes.presence, log_entry].compact.join("\n\n")
    )
  end

  def checklist_done?(key)
    document_checklist.is_a?(Hash) && document_checklist[key.to_s]
  end

  class InvalidTransition < StandardError; end
end
