require "application_system_test_case"

class DocumentUploadTest < ApplicationSystemTestCase
  setup do
    @student = users(:student_es)
    @draft = @student.homologation_requests.create!(
      subject: "System test draft", plan_key: "basico",
      status: "draft", privacy_accepted: true
    )
    @diploma_pdf    = make_pdf("diploma_test.pdf")
    @transcript_pdf = make_pdf("transcript_test.pdf")
    @passport_pdf   = make_pdf("passport_test.pdf")
  end

  test "student uploads required documents and submits the request" do
    sign_in_as @student
    visit homologation_request_path(@draft)

    assert_text I18n.t("requests.attachments.expected.diploma.title")

    attach_file "file_input_diploma",    @diploma_pdf,    make_visible: true
    assert_text "diploma_test.pdf",   wait: 5
    assert_text "1/3"

    attach_file "file_input_transcript", @transcript_pdf, make_visible: true
    assert_text "transcript_test.pdf", wait: 5
    assert_text "2/3"

    attach_file "file_input_passport",   @passport_pdf,   make_visible: true
    assert_text "passport_test.pdf",   wait: 5
    assert_text "3/3"

    submit_label = I18n.t("requests.actions.submit")
    assert_button submit_label
    click_on submit_label

    # UI-only wait. Polling the DB from the test thread holds the shared
    # transactional connection long enough to starve Puma serving the POST
    # on CI — Capybara polling the DOM via Selenium is out-of-process and
    # doesn't contend with the server-side connection.
    assert_text I18n.t("requests.next_step.submitted"), wait: 15
    assert_equal "submitted", @draft.reload.status
  end

  private
    def make_pdf(name)
      path = Rails.root.join("tmp", "system_test_#{name}")
      File.binwrite(path, "%PDF-1.4\n%\xE2\xE3\xCF\xD3\n1 0 obj\n<</Type/Catalog>>\nendobj\nxref\n0 1\n0000000000 65535 f\ntrailer\n<</Size 1>>\n%%EOF\n".b)
      path.to_s
    end
end
