require "test_helper"
require "zip"

class RequestArchiveTest < ActiveSupport::TestCase
  setup do
    @request = homologation_requests(:in_pipeline_es) # user: student_es, name "Anna"
    @archive = RequestArchive.new(@request)
  end

  test "filename names the archive after the student and the request id" do
    assert_equal "homologation_Anna_#{@request.id}.zip", @archive.filename
  end

  test "filename transliterates diacritics and replaces whitespace with underscores" do
    @request.user.update!(name: " María   García ")

    assert_equal "homologation_Maria_Garcia_#{@request.id}.zip", @archive.filename
  end

  test "filename falls back to 'student' when the name has no ASCII content" do
    # User.name carries a presence validation. The fallback exists for edge
    # cases — non-Latin scripts that transliterate to nothing, or DB rows that
    # predate the validation. Bypass via update_columns to exercise it.
    @request.user.update_columns(name: "")

    assert_equal "homologation_student_#{@request.id}.zip", @archive.filename
  end

  test "zip_body places every attached document inside a top-level folder named like the archive" do
    attach_request_document(@request, kind: "transcript", filename: "transcript.pdf")

    folder = "homologation_Anna_#{@request.id}"
    assert_includes entries_in(@archive.zip_body), "#{folder}/01_transcript.pdf"
  end

  test "zip_body orders entries with REQUIRED_KINDS first, then optional, numbered sequentially" do
    attach_request_document(@request, kind: "language_certificate", filename: "ielts.pdf")
    attach_request_document(@request, kind: "diploma",              filename: "dyplom.pdf")
    attach_request_document(@request, kind: "passport",             filename: "id.pdf")

    folder = "homologation_Anna_#{@request.id}"
    names  = entries_in(@archive.zip_body)

    assert_equal [
      "#{folder}/01_diploma.pdf",
      "#{folder}/02_passport.pdf",
      "#{folder}/03_language_certificate.pdf"
    ], names
  end

  test "zip_body preserves the original file extension" do
    attach_request_document(@request, kind: "diploma", filename: "scan.JPG", content_type: "image/jpeg")

    folder = "homologation_Anna_#{@request.id}"
    assert_includes entries_in(@archive.zip_body), "#{folder}/01_diploma.JPG"
  end

  private
    def entries_in(zip_body)
      names = []
      Zip::InputStream.open(StringIO.new(zip_body)) do |zip|
        while (entry = zip.get_next_entry)
          names << entry.name
        end
      end
      names
    end
end
