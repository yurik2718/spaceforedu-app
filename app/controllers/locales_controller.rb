class LocalesController < ApplicationController
  allow_unauthenticated_access
  skip_after_action :verify_authorized

  def update
    locale = params[:locale].to_s.to_sym
    if I18n.available_locales.include?(locale)
      session[:locale] = locale
      current_user&.update(locale: locale)
    end
    redirect_back fallback_location: root_path
  end
end
