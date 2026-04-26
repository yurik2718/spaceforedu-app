class PagesController < ApplicationController
  skip_after_action :verify_authorized

  def home
    return redirect_to admin_pipeline_path if Current.user&.super_admin?

    if Current.user&.student?
      @requests = Current.user.homologation_requests
                    .includes(:conversation)
                    .kept
                    .order(updated_at: :desc)
    end
  end
end
