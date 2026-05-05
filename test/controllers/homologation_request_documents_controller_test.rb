require "test_helper"

class HomologationRequestDocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:student_es)
    @draft   = @student.homologation_requests.create!(
      subject: "Draft for upload", service_type: "homologation",
      status: "draft", privacy_accepted: true
    )
  end

  test "valid PDF attaches and redirects with a notice" do
    sign_in_as @student
    pdf = Rack::Test::UploadedFile.new(StringIO.new("%PDF-1.4 fake"), "application/pdf", original_filename: "ok.pdf")

    assert_difference -> { @draft.documents.attachments.count }, 1 do
      post homologation_request_documents_path(@draft), params: { files: [ pdf ] }
    end

    assert_redirected_to homologation_request_path(@draft)
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

  test "a single oversized file is rejected and not retained" do
    sign_in_as @student
    huge = Rack::Test::UploadedFile.new(StringIO.new("x" * (16.megabytes)), "application/pdf", original_filename: "huge.pdf")

    assert_no_difference -> { @draft.documents.attachments.where.not(id: nil).count } do
      post homologation_request_documents_path(@draft), params: { files: [ huge ] }
    end

    assert_response :unprocessable_entity
  end

  test "a mixed-batch upload purges only the files attached in this request" do
    sign_in_as @student
    @draft.documents.attach(io: StringIO.new("%PDF pre-existing"), filename: "old.pdf", content_type: "application/pdf")
    pre_existing_id = @draft.documents.attachments.last.id

    good = Rack::Test::UploadedFile.new(StringIO.new("%PDF good"), "application/pdf", original_filename: "good.pdf")
    bad  = Rack::Test::UploadedFile.new(StringIO.new("plain"),     "text/plain",      original_filename: "notes.txt")

    post homologation_request_documents_path(@draft), params: { files: [ good, bad ] }

    assert_response :unprocessable_entity
    assert_equal [ pre_existing_id ], @draft.reload.documents.attachments.pluck(:id)
  end
end
