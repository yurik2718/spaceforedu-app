require "test_helper"

class PipelineFlowTest < ActiveSupport::TestCase
  setup { PipelineFlow.reload! }

  test "all_stages, kanban_stages and horizontal_stages match config" do
    assert_equal %w[pago_recibido documentos traduccion tasas_volantes redsara],
                 PipelineFlow.kanban_stages
    assert_equal %w[cotejo_ministerio cotejo_delegacion completado],
                 PipelineFlow.horizontal_stages
    assert_equal PipelineFlow.kanban_stages + PipelineFlow.horizontal_stages,
                 PipelineFlow.all_stages
  end

  test "next_stage walks the linear kanban sequence" do
    assert_equal "documentos",     PipelineFlow.next_stage("pago_recibido", country: "ES")
    assert_equal "traduccion",     PipelineFlow.next_stage("documentos",    country: "ES")
    assert_equal "tasas_volantes", PipelineFlow.next_stage("traduccion",    country: "ES")
    assert_equal "redsara",        PipelineFlow.next_stage("tasas_volantes", country: "ES")
  end

  test "next_stage from redsara branches by country, defaulting to delegacion" do
    assert_equal "cotejo_delegacion", PipelineFlow.next_stage("redsara", country: "ES")
    assert_equal "cotejo_delegacion", PipelineFlow.next_stage("redsara", country: "AR")
  end

  test "next_stage from cotejo always lands on completado" do
    assert_equal "completado", PipelineFlow.next_stage("cotejo_ministerio", country: "ES")
    assert_equal "completado", PipelineFlow.next_stage("cotejo_delegacion", country: "AR")
  end

  test "next_stage from completado is nil" do
    assert_nil PipelineFlow.next_stage("completado", country: "ES")
  end

  test "next_stage from blank starts the pipeline" do
    assert_equal "pago_recibido", PipelineFlow.next_stage(nil, country: "ES")
    assert_equal "pago_recibido", PipelineFlow.next_stage("", country: "ES")
  end

  test "previous_stage from pago_recibido is nil" do
    assert_nil PipelineFlow.previous_stage("pago_recibido", country: "ES")
  end

  test "previous_stage from cotejo always lands on redsara" do
    assert_equal "redsara", PipelineFlow.previous_stage("cotejo_ministerio", country: "ES")
    assert_equal "redsara", PipelineFlow.previous_stage("cotejo_delegacion", country: "AR")
  end

  test "previous_stage from completado returns the country-correct cotejo" do
    assert_equal "cotejo_delegacion", PipelineFlow.previous_stage("completado", country: "AR")
  end

  test "cotejo_for falls back to default when country not in ministerio list" do
    assert_equal "cotejo_delegacion", PipelineFlow.cotejo_for("AR")
    assert_equal "cotejo_delegacion", PipelineFlow.cotejo_for("ES")
  end
end
