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
    assert_response :ok
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
    assert_response :ok
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
end
