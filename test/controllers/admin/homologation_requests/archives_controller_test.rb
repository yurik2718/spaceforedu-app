require "test_helper"

class Admin::HomologationRequests::ArchivesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @hr = homologation_requests(:in_pipeline_es)
    @hr.documents.attach(io: StringIO.new("d"), filename: "transcript.pdf", content_type: "application/pdf")
    @hr.save!
  end

  test "super_admin downloads a zip archive" do
    sign_in_as users(:admin)

    get admin_homologation_request_archive_path(@hr)

    assert_response :success
    assert_equal "application/zip",                                 response.media_type
    assert_match %r{filename="request_#{@hr.id}\.zip"},        response.headers["Content-Disposition"]
  end

  test "students are redirected to root with not-authorized alert" do
    sign_in_as users(:student_es)

    get admin_homologation_request_archive_path(@hr)

    assert_redirected_to root_path
    assert_equal I18n.t("errors.not_authorized"), flash[:alert]
  end
end
