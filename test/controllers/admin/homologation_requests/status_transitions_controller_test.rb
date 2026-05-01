require "test_helper"

class Admin::HomologationRequests::StatusTransitionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @homologation_request = homologation_requests(:awaiting_payment)
    @admin   = users(:admin)
  end

  test "super_admin transitions status and is redirected" do
    sign_in_as @admin
    post admin_homologation_request_status_transitions_path(@homologation_request),
         params: { status_transition: { status: "in_review" } }

    assert_redirected_to admin_homologation_request_path(@homologation_request)
    assert_equal I18n.t("flash.status_changed"), flash[:notice]
    assert_equal "in_review", @homologation_request.reload.status
  end

  test "invalid status redirects with an alert" do
    sign_in_as @admin
    post admin_homologation_request_status_transitions_path(@homologation_request),
         params: { status_transition: { status: "bogus" } }

    assert_redirected_to admin_homologation_request_path(@homologation_request)
    assert_not_nil flash[:alert]
    assert_equal "awaiting_payment", @homologation_request.reload.status
  end

  test "students are redirected to root with not-authorized alert" do
    sign_in_as users(:student_es)
    post admin_homologation_request_status_transitions_path(@homologation_request),
         params: { status_transition: { status: "in_review" } }

    assert_redirected_to root_path
    assert_equal "awaiting_payment", @homologation_request.reload.status
  end

  test "unauthenticated visitors are redirected to sign in" do
    post admin_homologation_request_status_transitions_path(@homologation_request),
         params: { status_transition: { status: "in_review" } }
    assert_redirected_to new_session_path
  end
end
