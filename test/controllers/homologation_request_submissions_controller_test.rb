require "test_helper"

class HomologationRequestSubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:student_es)
    @other   = users(:student_other)
    @draft   = @student.homologation_requests.create!(
      subject: "draft", service_type: "homologation", status: "draft", privacy_accepted: true
    )
  end

  test "POST create transitions a draft to submitted and redirects" do
    sign_in_as @student
    post homologation_request_submission_path(@draft)

    assert_redirected_to homologation_request_path(@draft)
    assert_equal I18n.t("flash.request_submitted"), flash[:notice]
    @draft.reload
    assert_equal "submitted", @draft.status
    assert_equal @student.id, @draft.status_changed_by
  end

  test "POST create on a non-draft status redirects with an alert" do
    sign_in_as @student
    submitted = @student.homologation_requests.create!(
      subject: "x", service_type: "homologation", status: "submitted", privacy_accepted: true
    )

    post homologation_request_submission_path(submitted)

    assert_redirected_to homologation_request_path(submitted)
    assert_not_nil flash[:alert]
    assert_equal "submitted", submitted.reload.status
  end

  test "POST create by another student is rejected" do
    sign_in_as @other
    post homologation_request_submission_path(@draft)
    assert_redirected_to root_path
    assert_equal "draft", @draft.reload.status
  end

  test "POST create unauthenticated redirects to sign in" do
    post homologation_request_submission_path(@draft)
    assert_redirected_to new_session_path
  end
end
