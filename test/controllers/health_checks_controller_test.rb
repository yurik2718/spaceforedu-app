require "test_helper"

class HealthChecksControllerTest < ActionDispatch::IntegrationTest
  test "GET /up/db returns 200 when the database responds" do
    get "/up/db"
    assert_response :ok
  end

  test "GET /up/db returns 503 when the database raises" do
    real_connection = ActiveRecord::Base.connection
    fake = Object.new
    fake.define_singleton_method(:execute) { |_| raise ActiveRecord::ConnectionNotEstablished }

    ActiveRecord::Base.singleton_class.alias_method(:__real_connection, :connection)
    ActiveRecord::Base.singleton_class.define_method(:connection) { fake }

    get "/up/db"

    assert_response :service_unavailable
  ensure
    ActiveRecord::Base.singleton_class.alias_method(:connection, :__real_connection)
    ActiveRecord::Base.singleton_class.send(:remove_method, :__real_connection)
  end

  test "GET /up/queue returns 503 when no Solid Queue process has a recent heartbeat" do
    fake_relation = Object.new
    fake_relation.define_singleton_method(:any?) { false }

    SolidQueue::Process.singleton_class.alias_method(:__real_where, :where)
    SolidQueue::Process.singleton_class.define_method(:where) { |*| fake_relation }

    get "/up/queue"

    assert_response :service_unavailable
  ensure
    SolidQueue::Process.singleton_class.alias_method(:where, :__real_where)
    SolidQueue::Process.singleton_class.send(:remove_method, :__real_where)
  end

  test "GET /up/queue returns 200 when at least one process has a fresh heartbeat" do
    fake_relation = Object.new
    fake_relation.define_singleton_method(:any?) { true }

    SolidQueue::Process.singleton_class.alias_method(:__real_where, :where)
    SolidQueue::Process.singleton_class.define_method(:where) { |*| fake_relation }

    get "/up/queue"

    assert_response :ok
  ensure
    SolidQueue::Process.singleton_class.alias_method(:where, :__real_where)
    SolidQueue::Process.singleton_class.send(:remove_method, :__real_where)
  end
end
