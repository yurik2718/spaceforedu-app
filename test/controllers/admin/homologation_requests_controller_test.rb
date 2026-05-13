require "test_helper"

class Admin::HomologationRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @homologation_request = homologation_requests(:in_pipeline_es)
    @admin   = users(:admin)
    @student = users(:student_es)
  end

  test "GET show renders for super_admin" do
    sign_in_as @admin
    get admin_homologation_request_path(@homologation_request)
    assert_response :success
    assert_select "h1", text: /#{@homologation_request.subject}/
  end

  test "GET show redirects students to root" do
    sign_in_as @student
    get admin_homologation_request_path(@homologation_request)
    assert_redirected_to root_path
    assert_equal I18n.t("errors.not_authorized"), flash[:alert]
  end

  test "GET show redirects unauthenticated visitors to sign in" do
    get admin_homologation_request_path(@homologation_request)
    assert_redirected_to new_session_path
  end
end
