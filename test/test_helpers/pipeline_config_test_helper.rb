module PipelineConfigTestHelper
  def with_pipeline_fixture(filename)
    PipelineFlow.config_path = Rails.root.join("test/fixtures/files", filename)
    PipelineFlow.reload!
    yield
  ensure
    restore_pipeline_config
  end

  def restore_pipeline_config
    PipelineFlow.config_path = nil
    PipelineFlow.reload!
  end
end
