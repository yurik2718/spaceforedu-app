require "test_helper"
require "zip"

class RequestArchiveTest < ActiveSupport::TestCase
  setup do
    @request = homologation_requests(:in_pipeline_es)
    @request.documents.attach(io: StringIO.new("doc-bytes"), filename: "transcript.pdf", content_type: "application/pdf")
    @request.save!
  end

  test "zip_archive writes documents to the archive" do
    Zip::InputStream.open(StringIO.new(@request.zip_archive)) do |zip|
      entries = []
      while (entry = zip.get_next_entry)
        entries << entry.name
      end

      assert_includes entries, "transcript.pdf"
    end
  end

  test "zip_filename uses the request id" do
    assert_equal "request_#{@request.id}.zip", @request.zip_filename
  end
end
