class Admin::PipelinesController < ApplicationController
  STALE_AFTER = 7.days
  INBOX_STATUSES = %w[submitted in_review awaiting_reply].freeze

  def show
    authorize :pipeline

    base = policy_scope(HomologationRequest).kept

    @inbox = base.where(status: INBOX_STATUSES)
                 .includes(:user, :conversation)
                 .order(updated_at: :asc)
                 .to_a

    pipeline_scope = base.where.not(pipeline_stage: nil)
    pipeline_scope = pipeline_scope.where(year: params[:year]) if params[:year].present?
    records = pipeline_scope.includes(:user, :conversation).order(updated_at: :desc).to_a

    @kanban_stages = PipelineFlow.kanban_stages + PipelineFlow::COTEJO_STAGES
    @grouped       = group_by_stage(records)
    @stats         = build_stats(records)
    @stale_cutoff  = STALE_AFTER.ago
  end

  private
    def group_by_stage(records)
      PipelineFlow.all_stages.index_with { |stage| records.select { _1.pipeline_stage == stage } }
    end

    def build_stats(records)
      {
        active:  records.count { _1.pipeline_stage != PipelineFlow::TERMINAL_STAGE },
        revenue: records.sum { _1.amount }
      }
    end
end
