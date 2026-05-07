class HomologationRequestsController < ApplicationController
  def index
    scope = policy_scope(HomologationRequest).kept.order(updated_at: :desc)
    @pagy, @homologation_requests = pagy(scope)
  end

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
      redirect_to @homologation_request, notice: t("flash.request_created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @homologation_request = HomologationRequest.kept.includes(:conversation, :user).find(params[:id])
    authorize @homologation_request
    flash.now[:notice] = t("flash.payment_processing") if params[:payment] == "success"
  end

  def edit
    @homologation_request = HomologationRequest.kept.find(params[:id])
    authorize @homologation_request, :update?

    unless @homologation_request.editable?
      redirect_to @homologation_request, alert: t("flash.request_not_editable") and return
    end
  end

  def update
    @homologation_request = HomologationRequest.kept.find(params[:id])
    authorize @homologation_request

    unless @homologation_request.editable?
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
