require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @conversation       = conversations(:in_pipeline_es)
    @other_conversation = conversations(:at_redsara_other)
    @student            = users(:student_es)
    @admin              = users(:admin)
  end

  test "student sends message to their own conversation" do
    sign_in_as @student
    assert_difference "Message.count" do
      post conversation_messages_url(@conversation),
           params: { message: { body: "Hola, aquí van mis documentos." } },
           as: :turbo_stream
    end
    assert_response :no_content
  end

  test "student cannot send message to another student's conversation" do
    sign_in_as @student
    assert_no_difference "Message.count" do
      post conversation_messages_url(@other_conversation),
           params: { message: { body: "Intrusion attempt." } },
           as: :turbo_stream
    end
    assert_redirected_to root_url
  end

  test "admin sends message to any conversation" do
    sign_in_as @admin
    assert_difference "Message.count" do
      post conversation_messages_url(@conversation),
           params: { message: { body: "Por favor envíe el título original." } },
           as: :turbo_stream
    end
    assert_response :no_content
  end

  test "empty body is rejected" do
    sign_in_as @student
    assert_no_difference "Message.count" do
      post conversation_messages_url(@conversation),
           params: { message: { body: "" } },
           as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "unauthenticated user is redirected to login" do
    post conversation_messages_url(@conversation),
         params: { message: { body: "Hello" } }
    assert_redirected_to new_session_url
  end

  test "student reply on awaiting_reply request flips status to in_review" do
    request = @conversation.homologation_request
    request.update_columns(status: "awaiting_reply", status_changed_by: @admin.id, status_changed_at: 1.hour.ago)

    sign_in_as @student
    post conversation_messages_url(@conversation),
         params: { message: { body: "here you go" } },
         as: :turbo_stream

    assert_equal "in_review", request.reload.status
  end

  test "admin reply on awaiting_reply request leaves status unchanged" do
    request = @conversation.homologation_request
    request.update_columns(status: "awaiting_reply", status_changed_by: @admin.id, status_changed_at: 1.hour.ago)

    sign_in_as @admin
    post conversation_messages_url(@conversation),
         params: { message: { body: "still waiting" } },
         as: :turbo_stream

    assert_equal "awaiting_reply", request.reload.status
  end

  test "auto-advance from a student message does not self-notify the student" do
    request = @conversation.homologation_request
    request.update_columns(status: "awaiting_reply", status_changed_by: @admin.id, status_changed_at: 1.hour.ago)

    sign_in_as @student
    assert_no_difference -> { @student.notifications.count } do
      post conversation_messages_url(@conversation),
           params: { message: { body: "here you go" } },
           as: :turbo_stream
    end
  end
end
