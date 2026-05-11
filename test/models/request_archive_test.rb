require "test_helper"
require "zip"

class RequestArchiveTest < ActiveSupport::TestCase
  setup do
    @request = homologation_requests(:in_pipeline_es)
    attach_request_document(@request, kind: "transcript", filename: "transcript.pdf", content: "doc-bytes")
  end

  test "zip_archive writes documents to the archive" do
    Zip::InputStream.open(StringIO.new(@request.zip_archive)) do |zip|
      entries = []
      while (entry = zip.get_next_entry)
        entries << entry.name
      end

      assert_includes entries, "transcript-transcript.pdf"
    end
  end

  test "zip_filename uses the request id" do
    assert_equal "request_#{@request.id}.zip", @request.zip_filename
  end
end
