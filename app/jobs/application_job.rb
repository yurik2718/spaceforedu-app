require "net/smtp"

class ApplicationJob < ActiveJob::Base
  retry_on Net::SMTPError,                attempts: 5, wait: :polynomially_longer
  retry_on ActiveStorage::IntegrityError, attempts: 3, wait: 30.seconds

  discard_on ActiveJob::DeserializationError
  discard_on ActiveRecord::RecordNotFound
end
