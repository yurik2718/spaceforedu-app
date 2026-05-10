require "test_helper"

class HomologationRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:student_es)
    @other   = users(:student_other)
    @admin   = users(:admin)
    @owned   = homologation_requests(:in_pipeline_es)
    @draft   = homologation_requests(:awaiting_payment) # status: awaiting_payment, owned by student_es
  end

  # --- index ---

  test "GET index lists the signed-in student's kept requests, newest first" do
    sign_in_as @student
    second = @student.homologation_requests.create!(
      subject: "Second diploma", plan_key: "basico", status: "draft", privacy_accepted: true
    )

    get homologation_requests_path

    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(@owned)}"
    assert_select "##{ActionView::RecordIdentifier.dom_id(second)}"
  end

  test "GET index excludes other students' requests" do
    sign_in_as @other

    get homologation_requests_path

    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(@owned)}", count: 0
  end

  test "GET index without any kept requests renders the empty state CTA" do
    fresh = User.create!(email_address: "fresh@example.com", password: "secret", name: "Fresh", role: "student")
    sign_in_as fresh

    get homologation_requests_path

    assert_response :success
    assert_select "a[href=?]", new_homologation_request_path
  end

  # --- new ---

  test "GET new renders the form for a signed-in student" do
    sign_in_as @student
    get new_homologation_request_path

    assert_response :success
    assert_select "form[action=?]", homologation_requests_path
  end

  test "GET new redirects unauthenticated visitors to sign in" do
    get new_homologation_request_path
    assert_redirected_to new_session_path
  end

  # --- create ---

  test "POST create with valid params creates a draft request and redirects to show" do
    sign_in_as @student
    assert_difference("HomologationRequest.count", 1) do
      post homologation_requests_path, params: {
        homologation_request: {
          subject:              "My diploma",
          plan_key: "basico",
          description:          "Need help homologating",
          education_system:     "Universidad Nacional",
          university:           "UNAM",
          year:                 "2018",
          studies_finished:     "yes",
          language_knowledge:   "B2",
          language_certificate: "DELE B2",
          privacy_accepted:     "1"
        }
      }
    end

    created = HomologationRequest.order(:created_at).last
    assert_equal "draft",      created.status
    assert_equal @student.id,  created.user_id
    assert_redirected_to homologation_request_path(created)
    assert_equal I18n.t("flash.request_created"), flash[:notice]
  end

  test "POST create without privacy_accepted re-renders new" do
    sign_in_as @student
    assert_no_difference("HomologationRequest.count") do
      post homologation_requests_path, params: {
        homologation_request: {
          subject:          "x",
          plan_key: "basico",
          privacy_accepted: "0"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "POST create unauthenticated redirects to sign in" do
    assert_no_difference("HomologationRequest.count") do
      post homologation_requests_path, params: { homologation_request: { subject: "x", plan_key: "basico", privacy_accepted: "1" } }
    end
    assert_redirected_to new_session_path
  end

  # --- show ---

  test "GET show renders for the owner" do
    sign_in_as @student
    get homologation_request_path(@owned)
    assert_response :success
    assert_select "h1", text: /#{@owned.subject}/
  end

  test "GET show redirects to root for a different student" do
    sign_in_as @other
    get homologation_request_path(@owned)
    assert_redirected_to root_path
    assert_equal I18n.t("errors.not_authorized"), flash[:alert]
  end

  test "GET show works for super_admin" do
    sign_in_as @admin
    get homologation_request_path(@owned)
    assert_response :success
  end

  # --- edit ---

  test "GET edit allowed for draft status" do
    sign_in_as @student
    draft_request = @student.homologation_requests.create!(
      subject: "draft", plan_key: "basico", status: "draft", privacy_accepted: true
    )
    get edit_homologation_request_path(draft_request)
    assert_response :success
  end

  test "GET edit redirects with alert when status is not editable" do
    sign_in_as @student
    get edit_homologation_request_path(@owned) # status: payment_confirmed
    assert_redirected_to homologation_request_path(@owned)
    assert_not_nil flash[:alert]
  end

  test "GET edit redirects for non-owner" do
    sign_in_as @other
    draft_request = @student.homologation_requests.create!(
      subject: "draft", plan_key: "basico", status: "draft", privacy_accepted: true
    )
    get edit_homologation_request_path(draft_request)
    assert_redirected_to root_path
  end

  # --- update ---

  test "PATCH update updates a draft" do
    sign_in_as @student
    draft_request = @student.homologation_requests.create!(
      subject: "draft", plan_key: "basico", status: "draft", privacy_accepted: true
    )
    patch homologation_request_path(draft_request), params: {
      homologation_request: { subject: "Updated subject", university: "UPM" }
    }
    assert_redirected_to homologation_request_path(draft_request)
    assert_equal "Updated subject", draft_request.reload.subject
  end

  test "PATCH update on non-editable status is rejected" do
    sign_in_as @student
    patch homologation_request_path(@owned), params: {
      homologation_request: { subject: "x" }
    }
    assert_redirected_to homologation_request_path(@owned)
    assert_not_equal "x", @owned.reload.subject
  end
end
