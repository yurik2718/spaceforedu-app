ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require_relative "test_helpers/pipeline_config_test_helper"
require_relative "test_helpers/active_storage_test_helper"

# Provide deterministic values for any encrypted credential the app reads.
# CI runs without RAILS_MASTER_KEY, so the real credentials store is empty —
# this gives the Stripe webhook signing test a stable secret without coupling
# the suite to a production key.
Rails.application.credentials.config.deep_merge!(
  stripe: { webhook_secret: "whsec_test_only" }
)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
