require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:student_es)
  end

  test "GET show renders the current user's profile" do
    sign_in_as @student
    get profile_path

    assert_response :success
    assert_select "h1", text: /#{@student.name}/
  end

  test "GET show redirects unauthenticated visitors to sign in" do
    get profile_path
    assert_redirected_to new_session_path
  end

  test "GET edit renders the edit form" do
    sign_in_as @student
    get edit_profile_path

    assert_response :success
    assert_select "form[action=?]", profile_path
  end

  test "PATCH update changes profile attributes" do
    sign_in_as @student
    patch profile_path, params: {
      user: {
        name:                  "Anna Updated",
        country:               "AR",
        locale:                "ru",
        notification_email:    "1",
        notification_telegram: "0"
      }
    }

    assert_redirected_to profile_path
    assert_equal I18n.t("flash.user_updated"), flash[:notice]

    @student.reload
    assert_equal "Anna Updated", @student.name
    assert_equal "AR",           @student.country
    assert_equal "ru",           @student.locale
    assert @student.notification_email
    refute @student.notification_telegram
  end

  test "PATCH update with invalid params re-renders edit" do
    sign_in_as @student
    patch profile_path, params: { user: { name: "" } }
    assert_response :unprocessable_entity
    assert_equal "Anna", @student.reload.name
  end

  test "PATCH update unauthenticated redirects to sign in" do
    patch profile_path, params: { user: { name: "x" } }
    assert_redirected_to new_session_path
  end
end
