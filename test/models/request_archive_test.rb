require "test_helper"
require "zip"

class RequestArchiveTest < ActiveSupport::TestCase
  setup do
    @request = homologation_requests(:in_pipeline_es)
    @request.documents.attach(io: StringIO.new("doc-bytes"), filename: "transcript.pdf", content_type: "application/pdf")
    @request.originals.attach(io: StringIO.new("orig-bytes"), filename: "diploma.pdf", content_type: "application/pdf")
    @request.application_file.attach(io: StringIO.new("app-bytes"), filename: "modelo_790.pdf", content_type: "application/pdf")
    @request.save!
  end

  test "zip_archive writes attachments under documents/, originals/, and application/ namespaces" do
    Zip::InputStream.open(StringIO.new(@request.zip_archive)) do |zip|
      entries = []
      while (entry = zip.get_next_entry)
        entries << entry.name
      end

      assert_includes entries, "documents/transcript.pdf"
      assert_includes entries, "originals/diploma.pdf"
      assert_includes entries, "application/modelo_790.pdf"
    end
  end

  test "zip_filename uses the request id" do
    assert_equal "request_#{@request.id}.zip", @request.zip_filename
  end
end
