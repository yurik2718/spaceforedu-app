class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.application.credentials.dig(:brand, :support_email) || "noreply@example.com" }
  layout "mailer"
end
