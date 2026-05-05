require "test_helper"

class HomologationRequestDocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:student_es)
    @draft   = @student.homologation_requests.create!(
      subject: "Draft for upload", service_type: "homologation",
      status: "draft", privacy_accepted: true
    )
  end

  test "rejecting an unsupported content_type does not attach and surfaces errors on the request" do
    sign_in_as @student

    bad_file = Rack::Test::UploadedFile.new(StringIO.new("plain"), "text/plain", original_filename: "notes.txt")

    assert_no_difference "ActiveStorage::Attachment.count" do
      post homologation_request_documents_path(@draft), params: { files: [ bad_file ] }
    end

    assert_response :unprocessable_entity
    assert_select ".text-error", text: /document/i
  end
end
