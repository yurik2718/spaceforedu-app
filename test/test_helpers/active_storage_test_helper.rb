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
end

ActiveSupport.on_load(:active_support_test_case) { include ActiveStorageTestHelper }
ActiveSupport.on_load(:action_dispatch_integration_test) { include ActiveStorageTestHelper }
