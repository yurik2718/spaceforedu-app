module ApplicationHelper
  def flash_alert_class(type)
    case type.to_sym
    when :notice, :success then "alert-success"
    when :alert, :error    then "alert-error"
    when :warning          then "alert-warning"
    else                        "alert-info"
    end
  end

  def status_badge_class(status)
    case status
    when "draft"                        then "badge-neutral"
    when "submitted", "in_review"       then "badge-info"
    when "awaiting_reply",
         "awaiting_payment"             then "badge-warning"
    when "payment_confirmed", "resolved" then "badge-success"
    when "in_progress"                  then "badge-primary"
    when "closed"                       then "badge-neutral"
    else                                     "badge-neutral"
    end
  end

  def nav_link_class(section)
    current_page_section?(section) ? "active" : ""
  end

  def available_locales
    I18n.available_locales
  end

  def locale_label(locale)
    locale.to_s.upcase
  end

  # Language name in its OWN language — UX convention for language switchers.
  # Lets a user who doesn't know the current locale still find their language.
  NATIVE_LOCALE_LABELS = {
    en: "English",
    es: "Español",
    ru: "Русский"
  }.freeze

  def native_locale_label(locale)
    NATIVE_LOCALE_LABELS.fetch(locale.to_sym, locale.to_s.upcase)
  end

  # Brand contacts and identity. Stored in encrypted credentials
  # (`bin/rails credentials:edit` → `brand:` section) so real values stay
  # out of the public repo. Fallbacks are clearly-fake placeholders that
  # keep pages rendering during local setup before master.key arrives.
  def support_email
    Rails.application.credentials.dig(:brand, :support_email) || "support@example.com"
  end

  def support_whatsapp
    Rails.application.credentials.dig(:brand, :support_whatsapp) || "+00 000 000 000"
  end

  def support_whatsapp_url
    "https://wa.me/#{support_whatsapp.gsub(/\D/, '')}"
  end

  def brand_location
    Rails.application.credentials.dig(:brand, :location) || "City, Country"
  end

  def masked_phone(value)
    return "—" if value.blank?
    digits = value.to_s.gsub(/\D/, "")
    return "•" * value.to_s.length if digits.length < 4
    "#{'•' * (digits.length - 4)}#{digits.last(4)}"
  end

  private
    def current_page_section?(section)
      request.path.start_with?("/#{section}")
    end
end
