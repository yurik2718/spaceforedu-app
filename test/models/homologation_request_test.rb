require "test_helper"

class HomologationRequestTest < ActiveSupport::TestCase
  setup do
    @admin   = users(:admin)
    @request = homologation_requests(:in_pipeline_es)
  end

  test "advance_pipeline! moves to the next stage and stamps audit columns" do
    freeze_time do
      assert_equal "documentos", @request.pipeline_stage

      @request.advance_pipeline!(changed_by: @admin)
      @request.reload

      assert_equal "traduccion",   @request.pipeline_stage
      assert_equal Time.current,   @request.pipeline_changed_at
      assert_equal @admin.id,      @request.pipeline_changed_by
    end
  end

  test "advance_pipeline! at completado raises InvalidTransition" do
    request = homologation_requests(:at_completado)
    assert_raises(HomologationRequest::InvalidTransition) do
      request.advance_pipeline!(changed_by: @admin)
    end
  end

  test "advance_pipeline! from redsara branches by country" do
    es = homologation_requests(:at_redsara_es)
    es.advance_pipeline!(changed_by: @admin)
    assert_equal "cotejo_delegacion", es.reload.pipeline_stage

    ar = homologation_requests(:at_redsara_other)
    ar.advance_pipeline!(changed_by: @admin)
    assert_equal "cotejo_delegacion", ar.reload.pipeline_stage
  end

  test "retreat_pipeline! requires a non-blank reason" do
    assert_raises(ArgumentError) do
      @request.retreat_pipeline!(changed_by: @admin, reason: "")
    end
    assert_raises(ArgumentError) do
      @request.retreat_pipeline!(changed_by: @admin, reason: "   ")
    end
  end

  test "retreat_pipeline! moves back, stamps audit, and appends to pipeline_notes" do
    @request.retreat_pipeline!(changed_by: @admin, reason: "Wrong stage by mistake")
    @request.reload

    assert_equal "pago_recibido", @request.pipeline_stage
    assert_equal @admin.id,       @request.pipeline_changed_by
    assert_includes @request.pipeline_notes, "Wrong stage by mistake"
    assert_includes @request.pipeline_notes, @admin.email_address
    assert_includes @request.pipeline_notes, "documentos → pago_recibido"
  end

  test "retreat_pipeline! at pago_recibido raises InvalidTransition" do
    @request.update!(pipeline_stage: "pago_recibido")
    assert_raises(HomologationRequest::InvalidTransition) do
      @request.retreat_pipeline!(changed_by: @admin, reason: "test")
    end
  end

  test "confirm_payment! starts the pipeline at pago_recibido" do
    request = homologation_requests(:in_pipeline_es)
    request.update!(pipeline_stage: nil, status: "awaiting_payment")

    request.confirm_payment!(confirmed_by: @admin)
    request.reload

    assert_equal "pago_recibido",     request.pipeline_stage
    assert_equal "payment_confirmed", request.status
    assert_equal @admin.id,           request.pipeline_changed_by
  end

  test "checklist_done? reads serialized JSON" do
    assert @request.checklist_done?(:sol)
    refute @request.checklist_done?(:vol)
    refute @request.checklist_done?(:missing_key)
  end
end
