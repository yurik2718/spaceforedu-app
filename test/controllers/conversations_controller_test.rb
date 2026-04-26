require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @conversation = conversations(:in_pipeline_es)
    @student      = users(:student_es)
    @admin        = users(:admin)
  end

  test "student sees their own conversation" do
    sign_in_as @student
    get conversation_url(@conversation)
    assert_response :ok
  end

  test "student cannot see another student's conversation" do
    sign_in_as users(:student_other)
    get conversation_url(@conversation)
    assert_redirected_to root_url
  end

  test "admin sees any conversation" do
    sign_in_as @admin
    get conversation_url(@conversation)
    assert_response :ok
  end

  test "unauthenticated user is redirected to login" do
    get conversation_url(@conversation)
    assert_redirected_to new_session_url
  end
end
