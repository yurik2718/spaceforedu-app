require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "GET new renders the registration form" do
    get new_registration_path

    assert_response :success
    assert_select "form[action=?]", registration_path
  end

  test "POST create with valid params signs in the user and redirects to root" do
    freeze_time do
      assert_difference("User.count", 1) do
        post registration_path, params: {
          user: {
            email_address:         "newbie@example.com",
            password:              "secret123",
            password_confirmation: "secret123",
            name:                  "Newbie",
            privacy_accepted:      "1"
          }
        }
      end

      assert_redirected_to root_path
      assert cookies[:session_id]

      user = User.find_by!(email_address: "newbie@example.com")
      assert_equal Time.current, user.privacy_accepted_at
      assert_equal "student",    user.role
    end
  end

  test "POST create normalizes the email_address before persisting" do
    post registration_path, params: {
      user: {
        email_address:         " NEWBIE@EXAMPLE.COM ",
        password:              "secret123",
        password_confirmation: "secret123",
        name:                  "Newbie",
        privacy_accepted:      "1"
      }
    }

    assert User.exists?(email_address: "newbie@example.com")
  end

  test "POST create without privacy_accepted re-renders the form and persists nothing" do
    assert_no_difference("User.count") do
      post registration_path, params: {
        user: {
          email_address:         "newbie@example.com",
          password:              "secret123",
          password_confirmation: "secret123",
          name:                  "Newbie",
          privacy_accepted:      "0"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "POST create with mismatched passwords re-renders the form" do
    assert_no_difference("User.count") do
      post registration_path, params: {
        user: {
          email_address:         "newbie@example.com",
          password:              "secret123",
          password_confirmation: "different",
          name:                  "Newbie",
          privacy_accepted:      "1"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "POST create with duplicate email re-renders the form" do
    assert_no_difference("User.count") do
      post registration_path, params: {
        user: {
          email_address:         users(:admin).email_address.upcase,
          password:              "secret123",
          password_confirmation: "secret123",
          name:                  "Dup",
          privacy_accepted:      "1"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
