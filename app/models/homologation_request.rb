class HomologationRequest < ApplicationRecord
  belongs_to :user
  belongs_to :status_changer,    class_name: "User", optional: true, foreign_key: :status_changed_by
  belongs_to :payment_confirmer, class_name: "User", optional: true, foreign_key: :payment_confirmed_by
  belongs_to :pipeline_changer,  class_name: "User", optional: true, foreign_key: :pipeline_changed_by
  has_one    :conversation, dependent: :destroy

  has_one_attached  :application_file
  has_many_attached :originals
  has_many_attached :documents

  broadcasts_refreshes

  validates :application_file, :originals, :documents,
            content_type: %w[application/pdf image/jpeg image/png image/webp],
            size:         { less_than: 15.megabytes }

  serialize :document_checklist, coder: JSON

  scope :kept, -> { where(discarded_at: nil) }

  STATUSES = %w[
    draft submitted in_review awaiting_reply
    awaiting_payment payment_confirmed in_progress
    resolved closed
  ].freeze

  EDITABLE_STATUSES = %w[draft awaiting_reply].freeze

  after_create_commit :create_conversation

  def editable? = status.in?(EDITABLE_STATUSES)

  def transition_to!(new_status, changed_by:)
    unless STATUSES.include?(new_status.to_s)
      raise InvalidTransition, "Unknown status: #{new_status}"
    end

    if new_status.to_s == "submitted" && !ready_to_submit?
      raise InvalidTransition, "Request needs an application file and at least one supporting document"
    end

    transaction do
      update!(
        status:            new_status.to_s,
        status_changed_at: Time.current,
        status_changed_by: changed_by.id
      )
      notify_owner_of_status_change
    end
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
      notify_owner_of_payment_confirmed
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

  def ready_to_submit?
    application_file.attached? && documents.attached?
  end

  def checklist_done?(key)
    document_checklist.is_a?(Hash) && document_checklist[key.to_s]
  end

  def zip_filename = "request_#{id}.zip"

  def zip_archive
    buffer = Zip::OutputStream.write_buffer do |zip|
      documents.attachments.each { |a| write_zip_entry(zip, "documents",   a) }
      originals.attachments.each { |a| write_zip_entry(zip, "originals",   a) }
      write_zip_entry(zip, "application", application_file.attachment) if application_file.attached?
    end
    buffer.string
  end

  class InvalidTransition < StandardError; end

  private
    def notify_owner_of_status_change
      return if status_changed_by == user_id
      user.notify(
        notifiable:  self,
        title_key:   "notifications.status_changed.title",
        body_key:    "notifications.status_changed.body",
        subject:     subject,
        status_code: status
      )
    end

    def notify_owner_of_payment_confirmed
      user.notify(
        notifiable: self,
        title_key:  "notifications.payment_confirmed.title",
        body_key:   "notifications.payment_confirmed.body",
        subject:    subject
      )
    end

    def create_conversation
      Conversation.create!(homologation_request: self)
    end

    def write_zip_entry(zip, namespace, attachment)
      zip.put_next_entry("#{namespace}/#{attachment.filename}")
      attachment.blob.download { |chunk| zip.write(chunk) }
    end
end
