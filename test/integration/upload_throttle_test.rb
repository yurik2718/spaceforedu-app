require "test_helper"

class UploadThrottleTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    @request = homologation_requests(:in_pipeline_es)
  end

  test "throttles after 30 document POSTs/minute from a single IP" do
    path = "/homologation_requests/#{@request.id}/documents"

    30.times do
      post path, headers: { "REMOTE_ADDR" => "203.0.113.99" }
    end

    post path, headers: { "REMOTE_ADDR" => "203.0.113.99" }

    assert_response :too_many_requests
  end
end
