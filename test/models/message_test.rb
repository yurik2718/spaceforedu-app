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

  test "student message notifies the request owner's counterpart, not the sender" do
    admin   = users(:admin)
    request = @conversation.homologation_request

    assert_difference -> { admin.notifications.count }, 1 do
      assert_no_difference -> { @student.notifications.count } do
        @conversation.messages.create!(user: @student, body: "hello")
      end
    end

    notification = admin.notifications.order(:created_at).last
    assert_equal request, notification.notifiable
  end

  test "admin message notifies the student owner, not the admin sender" do
    admin = users(:admin)

    assert_difference -> { @student.notifications.count }, 1 do
      assert_no_difference -> { admin.notifications.count } do
        @conversation.messages.create!(user: admin, body: "hi back")
      end
    end
  end

  test "student message on an awaiting_reply request flips it to in_review" do
    request = @conversation.homologation_request
    request.update_columns(status: "awaiting_reply", status_changed_by: users(:admin).id, status_changed_at: 1.hour.ago)

    @conversation.messages.create!(user: @student, body: "here you go")

    assert_equal "in_review", request.reload.status
  end

  test "admin message on an awaiting_reply request leaves the status unchanged" do
    admin   = users(:admin)
    request = @conversation.homologation_request
    request.update_columns(status: "awaiting_reply", status_changed_by: admin.id, status_changed_at: 1.hour.ago)

    @conversation.messages.create!(user: admin, body: "still waiting")

    assert_equal "awaiting_reply", request.reload.status
  end

  test "auto-advance from a student message does not self-notify the student" do
    request = @conversation.homologation_request
    request.update_columns(status: "awaiting_reply", status_changed_by: users(:admin).id, status_changed_at: 1.hour.ago)

    assert_no_difference -> { @student.notifications.count } do
      @conversation.messages.create!(user: @student, body: "here you go")
    end
  end
end
