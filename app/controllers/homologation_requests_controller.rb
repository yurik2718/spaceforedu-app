class HomologationRequestsController < ApplicationController
  EDITABLE_STATUSES = %w[draft awaiting_reply].freeze

  def new
    @homologation_request = Current.user.homologation_requests.new(service_type: "homologation")
    authorize @homologation_request
  end

  def create
    @homologation_request = Current.user.homologation_requests.new(request_params)
    authorize @homologation_request

    unless privacy_accepted?
      @homologation_request.errors.add(:privacy_accepted, :acceptance, message: t("errors.privacy_required"))
      return render :new, status: :unprocessable_entity
    end

    @homologation_request.privacy_accepted = true
    @homologation_request.status           = "draft"

    if @homologation_request.save
      @homologation_request.create_conversation!
      redirect_to @homologation_request, notice: t("flash.request_created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @homologation_request = HomologationRequest.kept.includes(:conversation, :user).find(params[:id])
    authorize @homologation_request
    @homologation_request.create_conversation! unless @homologation_request.conversation
  end

  def edit
    @homologation_request = HomologationRequest.kept.find(params[:id])
    authorize @homologation_request, :update?

    unless EDITABLE_STATUSES.include?(@homologation_request.status)
      redirect_to @homologation_request, alert: t("flash.request_not_editable") and return
    end
  end

  def update
    @homologation_request = HomologationRequest.kept.find(params[:id])
    authorize @homologation_request

    unless EDITABLE_STATUSES.include?(@homologation_request.status)
      redirect_to @homologation_request, alert: t("flash.request_not_editable") and return
    end

    if @homologation_request.update(request_params)
      redirect_to @homologation_request, notice: t("flash.request_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def request_params
      params.expect(homologation_request: %i[
        subject service_type description education_system university year
        studies_finished language_knowledge language_certificate
      ])
    end

    def privacy_accepted?
      params.dig(:homologation_request, :privacy_accepted) == "1"
    end
end
