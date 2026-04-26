require "test_helper"

class HomologationRequestTest < ActiveSupport::TestCase
  include PipelineConfigTestHelper

  setup do
    @admin   = users(:admin)
    @request = homologation_requests(:in_pipeline_es)
  end

  test "STATUSES enumerates the valid request lifecycle states" do
    assert_equal %w[draft submitted in_review awaiting_reply
                    awaiting_payment payment_confirmed in_progress
                    resolved closed],
                 HomologationRequest::STATUSES
  end

  test ".kept excludes soft-deleted requests" do
    kept    = homologation_requests(:in_pipeline_es)
    trashed = homologation_requests(:discarded)

    assert_includes     HomologationRequest.kept, kept
    assert_not_includes HomologationRequest.kept, trashed
  end

  test "transition_to! updates status and stamps the audit columns" do
    freeze_time do
      @request.transition_to!("in_review", changed_by: @admin)
      @request.reload

      assert_equal "in_review",  @request.status
      assert_equal Time.current, @request.status_changed_at
      assert_equal @admin.id,    @request.status_changed_by
    end
  end

  test "transition_to! accepts a symbol and writes it as a string" do
    @request.transition_to!(:in_review, changed_by: @admin)

    assert_equal "in_review", @request.reload.status
  end

  test "transition_to! raises InvalidTransition for an unknown status" do
    assert_raises(HomologationRequest::InvalidTransition) do
      @request.transition_to!("nonsense", changed_by: @admin)
    end
  end

  test "DB check_constraint rejects unknown status when the model is bypassed" do
    assert_raises(ActiveRecord::StatementInvalid) do
      @request.update_column(:status, "garbage")
    end
  end

  test "confirm_payment! seeds the pipeline, transitions status, and stamps both audit trails" do
    request = homologation_requests(:awaiting_payment)

    freeze_time do
      request.confirm_payment!(confirmed_by: @admin)
      request.reload

      assert_equal "pago_recibido",     request.pipeline_stage
      assert_equal "payment_confirmed", request.status
      assert_equal Time.current,        request.payment_confirmed_at
      assert_equal Time.current,        request.pipeline_changed_at
      assert_equal Time.current,        request.status_changed_at
      assert_equal @admin.id,           request.payment_confirmed_by
      assert_equal @admin.id,           request.pipeline_changed_by
      assert_equal @admin.id,           request.status_changed_by
    end
  end

  test "confirm_payment! is atomic: rolls back audit columns if the status transition fails" do
    request = homologation_requests(:awaiting_payment)
    request.singleton_class.define_method(:transition_to!) { |*| raise "boom" }

    assert_raises(RuntimeError) { request.confirm_payment!(confirmed_by: @admin) }

    request.reload
    assert_nil request.payment_confirmed_at
    assert_nil request.payment_confirmed_by
    assert_nil request.pipeline_stage
    assert_nil request.pipeline_changed_at
    assert_nil request.pipeline_changed_by
    assert_equal "awaiting_payment", request.status
  end

  test "advance_pipeline! moves to the next stage and stamps audit columns" do
    freeze_time do
      assert_equal "documentos", @request.pipeline_stage

      @request.advance_pipeline!(changed_by: @admin)
      @request.reload

      assert_equal "traduccion", @request.pipeline_stage
      assert_equal Time.current, @request.pipeline_changed_at
      assert_equal @admin.id,    @request.pipeline_changed_by
    end
  end

  test "advance_pipeline! at completado raises InvalidTransition" do
    finished = homologation_requests(:at_completado)

    assert_raises(HomologationRequest::InvalidTransition) do
      finished.advance_pipeline!(changed_by: @admin)
    end
  end

  test "advance_pipeline! from redsara routes by user.country through PipelineFlow" do
    with_pipeline_fixture("pipeline_with_ministerio.yml") do
      es    = homologation_requests(:at_redsara_es)
      other = homologation_requests(:at_redsara_other)

      es.advance_pipeline!(changed_by: @admin)
      other.advance_pipeline!(changed_by: @admin)

      assert_equal "cotejo_ministerio", es.reload.pipeline_stage
      assert_equal "cotejo_delegacion", other.reload.pipeline_stage
    end
  end

  test "pipeline_changer association resolves to the user who last touched the pipeline" do
    @request.advance_pipeline!(changed_by: @admin)

    assert_equal @admin, @request.reload.pipeline_changer
  end

  test "retreat_pipeline! requires a non-blank reason" do
    assert_raises(ArgumentError) do
      @request.retreat_pipeline!(changed_by: @admin, reason: "")
    end
    assert_raises(ArgumentError) do
      @request.retreat_pipeline!(changed_by: @admin, reason: "   ")
    end
  end

  test "retreat_pipeline! moves to the previous stage and stamps audit columns" do
    freeze_time do
      @request.retreat_pipeline!(changed_by: @admin, reason: "Wrong stage")
      @request.reload

      assert_equal "pago_recibido", @request.pipeline_stage
      assert_equal Time.current,    @request.pipeline_changed_at
      assert_equal @admin.id,       @request.pipeline_changed_by
    end
  end

  test "retreat_pipeline! log entry is formatted as [iso8601] email old_stage → new_stage: reason" do
    freeze_time do
      @request.retreat_pipeline!(changed_by: @admin, reason: "Wrong stage by mistake")

      expected = "[#{Time.current.iso8601}] #{@admin.email_address} documentos → pago_recibido: Wrong stage by mistake"
      assert_equal expected, @request.reload.pipeline_notes
    end
  end

  test "retreat_pipeline! appends each retreat as a new paragraph in pipeline_notes" do
    @request.retreat_pipeline!(changed_by: @admin, reason: "first try")
    @request.advance_pipeline!(changed_by: @admin)
    @request.retreat_pipeline!(changed_by: @admin, reason: "second try")

    notes = @request.reload.pipeline_notes
    assert_match(/first try.*\n\n.*second try/m, notes)
  end

  test "retreat_pipeline! at pago_recibido raises InvalidTransition" do
    request = homologation_requests(:at_pago_recibido)

    assert_raises(HomologationRequest::InvalidTransition) do
      request.retreat_pipeline!(changed_by: @admin, reason: "test")
    end
  end

  test "checklist_done? reads serialized JSON" do
    assert @request.checklist_done?(:sol)
    refute @request.checklist_done?(:vol)
    refute @request.checklist_done?(:missing_key)
  end

  test "document_checklist round-trips as a Hash through the database" do
    @request.update!(document_checklist: { "sol" => true, "vol" => true, "extra" => false })

    reloaded = HomologationRequest.find(@request.id)

    assert_equal({ "sol" => true, "vol" => true, "extra" => false }, reloaded.document_checklist)
  end
end
