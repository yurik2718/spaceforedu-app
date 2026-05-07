class Admin::PipelinesController < ApplicationController
  def show
    authorize :pipeline

    scope = policy_scope(HomologationRequest).kept.where.not(pipeline_stage: nil)
    scope = scope.where(year: params[:year]) if params[:year].present?

    @kanban_stages     = PipelineFlow.kanban_stages
    @horizontal_stages = PipelineFlow.horizontal_stages

    records  = scope.includes(:user).order(updated_at: :desc).to_a
    @grouped = group_by_stage(records)
    @stats   = build_stats(records)
  end

  private
    def group_by_stage(records)
      PipelineFlow.all_stages.index_with { |stage| records.select { _1.pipeline_stage == stage } }
    end

    def build_stats(records)
      {
        active:  records.count { _1.pipeline_stage != PipelineFlow::TERMINAL_STAGE },
        revenue: records.sum { _1.payment_amount.to_f }
      }
    end
end
