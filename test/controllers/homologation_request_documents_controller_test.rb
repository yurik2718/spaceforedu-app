require "test_helper"

class HomologationRequestDocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:student_es)
    @draft   = @student.homologation_requests.create!(
      subject: "Draft for upload", plan_key: "basico",
      status: "draft", privacy_accepted: true
    )
  end

  test "valid PDF attaches and redirects with a notice" do
    sign_in_as @student

    assert_difference -> { @draft.documents.attachments.count }, 1 do
      post homologation_request_documents_path(@draft),
           params: { files: [ direct_upload_blob ] }
    end

    assert_redirected_to homologation_request_path(@draft)
  end

  test "rejecting an unsupported content_type does not keep the attachment" do
    sign_in_as @student

    post homologation_request_documents_path(@draft),
         params: { files: [ direct_upload_blob(filename: "notes.txt", content: "plain", content_type: "text/plain") ] }

    assert_response :unprocessable_entity
    assert_select ".text-error", text: /document/i
    assert_equal 0, @draft.reload.documents.attachments.count
  end

  test "a single oversized file is rejected and not retained" do
    sign_in_as @student

    post homologation_request_documents_path(@draft),
         params: { files: [ direct_upload_blob(content: "x" * (16.megabytes), filename: "huge.pdf") ] }

    assert_response :unprocessable_entity
    assert_equal 0, @draft.reload.documents.attachments.count
  end

  test "Turbo Stream response replaces the documents frame with the errors-bearing partial" do
    sign_in_as @student

    post homologation_request_documents_path(@draft),
         params:  { files: [ direct_upload_blob(filename: "notes.txt", content: "plain", content_type: "text/plain") ] },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :unprocessable_entity
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match %r{<turbo-stream\s+action="replace"\s+target="#{ActionView::RecordIdentifier.dom_id(@draft, :documents)}"},
                 response.body
    assert_match(/text-error/, response.body)
  end

  test "uploading documents while awaiting_reply pings the super admin" do
    awaiting_reply = @student.homologation_requests.create!(
      subject: "Reply needed", plan_key: "basico",
      status: "awaiting_reply", privacy_accepted: true
    )
    admin = users(:admin)
    sign_in_as @student

    assert_difference -> {
      admin.notifications.where(notifiable: awaiting_reply, title_key: "notifications.documents_added.title").count
    }, 1 do
      post homologation_request_documents_path(awaiting_reply),
           params: { files: [ direct_upload_blob(filename: "reply.pdf") ] }
    end
  end

  test "uploading documents while in draft does not ping the super admin" do
    sign_in_as @student
    admin = users(:admin)

    assert_no_difference -> { admin.notifications.where(notifiable: @draft).count } do
      post homologation_request_documents_path(@draft),
           params: { files: [ direct_upload_blob ] }
    end
  end

  test "a mixed-batch upload purges only the files attached in this request" do
    sign_in_as @student
    @draft.documents.attach(io: StringIO.new("%PDF pre-existing"), filename: "old.pdf", content_type: "application/pdf")
    pre_existing_id = @draft.documents.attachments.last.id

    post homologation_request_documents_path(@draft), params: {
      files: [
        direct_upload_blob(filename: "good.pdf"),
        direct_upload_blob(filename: "notes.txt", content: "plain", content_type: "text/plain")
      ]
    }

    assert_response :unprocessable_entity
    assert_equal [ pre_existing_id ], @draft.reload.documents.attachments.pluck(:id)
  end
end
