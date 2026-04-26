require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "current_user resolves to the signed-in user during an authenticated request" do
    user = users(:admin)
    sign_in_as user

    get admin_pipeline_path

    assert_response :success
    assert_select ".avatar span", text: user.initials
  end
end
