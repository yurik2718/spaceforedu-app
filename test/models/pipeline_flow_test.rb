require "test_helper"

class PipelineFlowTest < ActiveSupport::TestCase
  include PipelineConfigTestHelper

  setup    { PipelineFlow.reload! }
  teardown { restore_pipeline_config }

  test "STARTING_STAGE and TERMINAL_STAGE name the first kanban and last horizontal stage" do
    assert_equal "pago_recibido", PipelineFlow::STARTING_STAGE
    assert_equal "completado",    PipelineFlow::TERMINAL_STAGE
    assert_equal PipelineFlow::STARTING_STAGE, PipelineFlow.kanban_stages.first
    assert_equal PipelineFlow::TERMINAL_STAGE, PipelineFlow.horizontal_stages.last
  end

  test "kanban_stages, horizontal_stages and all_stages match config" do
    assert_equal %w[pago_recibido documentos traduccion tasas_volantes redsara],
                 PipelineFlow.kanban_stages
    assert_equal %w[cotejo_ministerio cotejo_delegacion completado],
                 PipelineFlow.horizontal_stages
    assert_equal PipelineFlow.kanban_stages + PipelineFlow.horizontal_stages,
                 PipelineFlow.all_stages
  end

  test "checklist_keys returns the keys defined in config" do
    assert_equal %w[sol vol tas cer tit], PipelineFlow.checklist_keys
  end

  test "next_stage walks the linear kanban sequence forward" do
    assert_equal "documentos",     PipelineFlow.next_stage("pago_recibido",  country: "ES")
    assert_equal "traduccion",     PipelineFlow.next_stage("documentos",     country: "ES")
    assert_equal "tasas_volantes", PipelineFlow.next_stage("traduccion",     country: "ES")
    assert_equal "redsara",        PipelineFlow.next_stage("tasas_volantes", country: "ES")
  end

  test "previous_stage walks the linear kanban sequence backward" do
    assert_equal "tasas_volantes", PipelineFlow.previous_stage("redsara",        country: "ES")
    assert_equal "traduccion",     PipelineFlow.previous_stage("tasas_volantes", country: "ES")
    assert_equal "documentos",     PipelineFlow.previous_stage("traduccion",     country: "ES")
    assert_equal "pago_recibido",  PipelineFlow.previous_stage("documentos",     country: "ES")
  end

  test "next_stage from blank starts the pipeline at pago_recibido" do
    assert_equal "pago_recibido", PipelineFlow.next_stage(nil, country: "ES")
    assert_equal "pago_recibido", PipelineFlow.next_stage("",  country: "ES")
  end

  test "previous_stage from pago_recibido is nil" do
    assert_nil PipelineFlow.previous_stage("pago_recibido", country: "ES")
  end

  test "next_stage from completado is nil" do
    assert_nil PipelineFlow.next_stage("completado", country: "ES")
  end

  test "next_stage from an unknown stage is nil" do
    assert_nil PipelineFlow.next_stage("garbage", country: "ES")
  end

  test "previous_stage from an unknown stage is nil" do
    assert_nil PipelineFlow.previous_stage("garbage", country: "ES")
  end

  test "next_stage from cotejo_ministerio lands on completado" do
    assert_equal "completado", PipelineFlow.next_stage("cotejo_ministerio", country: "anywhere")
  end

  test "next_stage from cotejo_delegacion lands on completado" do
    assert_equal "completado", PipelineFlow.next_stage("cotejo_delegacion", country: "anywhere")
  end

  test "previous_stage from cotejo_ministerio lands on redsara" do
    assert_equal "redsara", PipelineFlow.previous_stage("cotejo_ministerio", country: "anywhere")
  end

  test "previous_stage from cotejo_delegacion lands on redsara" do
    assert_equal "redsara", PipelineFlow.previous_stage("cotejo_delegacion", country: "anywhere")
  end

  test "next_stage from redsara routes ministerio countries to cotejo_ministerio" do
    with_pipeline_fixture("pipeline_with_ministerio.yml") do
      assert_equal "cotejo_ministerio", PipelineFlow.next_stage("redsara", country: "ES")
    end
  end

  test "next_stage from redsara routes other countries to cotejo_delegacion" do
    with_pipeline_fixture("pipeline_with_ministerio.yml") do
      assert_equal "cotejo_delegacion", PipelineFlow.next_stage("redsara", country: "AR")
    end
  end

  test "previous_stage from completado returns cotejo_ministerio for ministerio countries" do
    with_pipeline_fixture("pipeline_with_ministerio.yml") do
      assert_equal "cotejo_ministerio", PipelineFlow.previous_stage("completado", country: "ES")
    end
  end

  test "previous_stage from completado returns cotejo_delegacion for other countries" do
    with_pipeline_fixture("pipeline_with_ministerio.yml") do
      assert_equal "cotejo_delegacion", PipelineFlow.previous_stage("completado", country: "AR")
    end
  end

  test "cotejo_for returns cotejo_ministerio for countries listed in ministerio_countries" do
    with_pipeline_fixture("pipeline_with_ministerio.yml") do
      assert_equal "cotejo_ministerio", PipelineFlow.cotejo_for("ES")
    end
  end

  test "cotejo_for falls back to default for countries not listed" do
    with_pipeline_fixture("pipeline_with_ministerio.yml") do
      assert_equal "cotejo_delegacion", PipelineFlow.cotejo_for("AR")
    end
  end

end
