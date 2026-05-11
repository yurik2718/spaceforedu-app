module FilenameSlug
  # Turns a free-form student name into a filesystem-safe token suitable for
  # filenames and ZIP folders. Transliterates diacritics, collapses any non
  # ASCII-alphanumeric run into a single underscore, trims edges, and falls
  # back to "student" if nothing usable remains (e.g. names in scripts that
  # transliterate to empty).
  def self.from(name)
    I18n.transliterate(name.to_s.strip)
      .gsub(/[^A-Za-z0-9]+/, "_")
      .gsub(/^_|_$/, "")
      .presence || "student"
  end
end
