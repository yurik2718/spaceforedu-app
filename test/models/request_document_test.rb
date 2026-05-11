require "test_helper"

class RequestDocumentTest < ActiveSupport::TestCase
  setup do
    @hr = homologation_requests(:in_pipeline_es)
  end

  test "kind must be in KINDS" do
    doc = @hr.request_documents.build(kind: "secret")
    doc.file.attach(io: StringIO.new("%PDF"), filename: "x.pdf", content_type: "application/pdf")

    refute doc.valid?
    assert doc.errors[:kind].any?
  end

  test "file is required" do
    doc = @hr.request_documents.build(kind: "diploma")

    refute doc.valid?
    assert doc.errors[:file].any?
  end

  test "kind is unique per homologation_request" do
    attach_request_document(@hr, kind: "diploma")
    dup = @hr.request_documents.build(kind: "diploma")
    dup.file.attach(io: StringIO.new("%PDF"), filename: "x.pdf", content_type: "application/pdf")

    refute dup.valid?
    assert dup.errors[:kind].any?
  end

  test "required scope returns only required kinds" do
    attach_request_document(@hr, kind: "diploma")
    attach_request_document(@hr, kind: "language_certificate")

    assert_equal %w[diploma], @hr.request_documents.required.pluck(:kind)
  end

  test "download_filename combines kind and a transliterated student slug" do
    @hr.user.update!(name: "María García")
    doc = attach_request_document(@hr, kind: "diploma", filename: "scan.pdf")

    assert_equal "diploma_Maria_Garcia.pdf", doc.download_filename
  end

  test "download_filename preserves the original file extension" do
    doc = attach_request_document(@hr, kind: "passport", filename: "photo.JPG", content_type: "image/jpeg")

    assert_equal "passport_Anna.JPG", doc.download_filename
  end

  test "download_filename falls back to 'student' when the student's name has no ASCII content" do
    @hr.user.update_columns(name: "")
    doc = attach_request_document(@hr, kind: "diploma", filename: "scan.pdf")

    assert_equal "diploma_student.pdf", doc.download_filename
  end

  test "ready_to_submit? requires all REQUIRED_KINDS" do
    refute @hr.ready_to_submit?

    RequestDocument::REQUIRED_KINDS[0..-2].each { |k| attach_request_document(@hr, kind: k) }
    refute @hr.ready_to_submit?

    attach_request_document(@hr, kind: RequestDocument::REQUIRED_KINDS.last)
    assert @hr.reload.ready_to_submit?
  end
end
