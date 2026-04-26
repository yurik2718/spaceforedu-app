require "test_helper"
require "turbo/broadcastable/test_helper"

class MessageTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  setup do
    @conversation = conversations(:in_pipeline_es)
    @student      = users(:student_es)
  end

  test "after_create_commit broadcasts an append to the conversation stream" do
    assert_turbo_stream_broadcasts(@conversation, count: 1) do
      @conversation.messages.create!(user: @student, body: "Hi")
    end
  end

  test "after_create_commit touches conversation.last_message_at with the message timestamp" do
    message = @conversation.messages.create!(user: @student, body: "Updated at?")

    assert_equal message.created_at, @conversation.reload.last_message_at
  end

  test "touch_conversation writes each new message's timestamp into last_message_at" do
    @conversation.messages.create!(user: @student, body: "first",  created_at: 2.hours.ago)
    later = @conversation.messages.create!(user: @student, body: "second", created_at: 1.minute.ago)

    assert_equal later.created_at, @conversation.reload.last_message_at
  end

  test "creating a message without body is invalid" do
    assert_raises(ActiveRecord::RecordInvalid) do
      @conversation.messages.create!(user: @student, body: nil)
    end
  end
end
