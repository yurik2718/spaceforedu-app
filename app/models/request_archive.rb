class RequestArchive
  KINDS_ORDER = (RequestDocument::REQUIRED_KINDS +
                 (RequestDocument::KINDS - RequestDocument::REQUIRED_KINDS)).freeze

  def initialize(request)
    @request = request
  end

  # The base name appears three places: as the .zip filename, as the top-level
  # folder *inside* the archive (so macOS unpacks into a named directory
  # instead of strewing files across Downloads), and — by association — as the
  # title an admin sees when triaging twenty cases in one afternoon.
  def filename
    "#{folder}.zip"
  end

  def zip_body
    buffer = Zip::OutputStream.write_buffer do |zip|
      ordered_documents.each_with_index do |doc, i|
        ext = File.extname(doc.file.filename.to_s)
        zip.put_next_entry("#{folder}/#{format('%02d', i + 1)}_#{doc.kind}#{ext}")
        doc.file.blob.download { |chunk| zip.write(chunk) }
      end
    end
    buffer.string
  end

  private
    def folder
      "homologation_#{FilenameSlug.from(@request.user.name)}_#{@request.id}"
    end

    def ordered_documents
      @request.request_documents
        .includes(file_attachment: :blob)
        .select { |doc| doc.file.attached? }
        .sort_by { |doc| KINDS_ORDER.index(doc.kind) || KINDS_ORDER.size }
    end
end
