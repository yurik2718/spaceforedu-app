module ActiveStorageTestHelper
  # Simulates what the browser's direct-upload JS sends after uploading a file:
  # the file is already in storage and the form posts only the blob's signed ID.
  def direct_upload_blob(filename: "test.pdf", content: "%PDF-1.4 fake", content_type: "application/pdf")
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(content),
      filename: filename,
      content_type: content_type
    ).signed_id
  end

  def upload_fixture(filename: "test.pdf", content: "%PDF-1.4 fake", content_type: "application/pdf")
    Rack::Test::UploadedFile.new(StringIO.new(content), content_type, original_filename: filename)
  end

  def attach_request_document(hr, kind:, filename: "file.pdf", content: "%PDF-1.4 ok", content_type: "application/pdf")
    doc = hr.request_documents.build(kind: kind)
    doc.file.attach(io: StringIO.new(content), filename: filename, content_type: content_type)
    doc.save!
    doc
  end
end

ActiveSupport.on_load(:active_support_test_case) { include ActiveStorageTestHelper }
ActiveSupport.on_load(:action_dispatch_integration_test) { include ActiveStorageTestHelper }
