class Admin::PipelinesController < ApplicationController
  def show
    authorize :pipeline

    scope = policy_scope(HomologationRequest).kept
              .where.not(pipeline_stage: nil)
              .includes(:user)
    scope = scope.where(year: params[:year]) if params[:year].present?

    @kanban_stages     = PipelineFlow.kanban_stages
    @horizontal_stages = PipelineFlow.horizontal_stages
    @grouped           = group_by_stage(scope)
    @stats             = build_stats(scope)
  end

  private
    def group_by_stage(scope)
      PipelineFlow.all_stages.index_with do |stage|
        scope.where(pipeline_stage: stage).order(updated_at: :desc)
      end
    end

    def build_stats(scope)
      {
        active:  scope.where.not(pipeline_stage: PipelineFlow::TERMINAL_STAGE).count,
        revenue: scope.sum(:payment_amount).to_f
      }
    end
end
