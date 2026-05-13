require "test_helper"

class StripeWebhookThrottleTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  test "throttles after 60 requests/minute from a single IP" do
    60.times do
      post "/stripe/webhooks", headers: { "REMOTE_ADDR" => "203.0.113.7" }
    end

    post "/stripe/webhooks", headers: { "REMOTE_ADDR" => "203.0.113.7" }

    assert_response :too_many_requests
  end
end
