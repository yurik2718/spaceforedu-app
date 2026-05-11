class RequestDocument < ApplicationRecord
  KINDS          = %w[diploma transcript passport language_certificate apostille translation].freeze
  REQUIRED_KINDS = %w[diploma transcript passport].freeze

  belongs_to :homologation_request, inverse_of: :request_documents
  has_one_attached :file

  validates :kind, inclusion: { in: KINDS }, uniqueness: { scope: :homologation_request_id }
  validates :file, attached: true,
                   content_type: %w[application/pdf image/jpeg image/png image/webp],
                   size: { less_than: 15.megabytes }

  scope :required, -> { where(kind: REQUIRED_KINDS) }

  def required? = REQUIRED_KINDS.include?(kind)
end
