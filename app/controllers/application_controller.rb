class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale
  after_action  :verify_authorized, except: :index
  after_action  :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private
    def switch_locale(&action)
      locale = current_user&.locale || locale_from_browser || I18n.default_locale
      I18n.with_locale(locale, &action)
    end

    def locale_from_browser
      request.env["HTTP_ACCEPT_LANGUAGE"]
        &.scan(/[a-z]{2}/i)
        &.map(&:downcase)
        &.map(&:to_sym)
        &.find { |l| I18n.available_locales.include?(l) }
    end

    def user_not_authorized
      redirect_to root_path, alert: t("errors.not_authorized")
    end
end
