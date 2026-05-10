# Pre-baked chat templates for super_admin. Stored in config/quick_replies.yml.
# No DB row, no admin UI — edit YAML and deploy.
class QuickReply
  attr_reader :id, :label, :body

  def initialize(id:, label:, body:)
    @id    = id
    @label = label
    @body  = body.strip
  end

  def render(vars)
    body.gsub(/\{(\w+)\}/) { vars[Regexp.last_match(1).to_sym].to_s }
  end

  class << self
    attr_writer :config_path

    def config_path
      @config_path ||= Rails.root.join("config/quick_replies.yml")
    end

    def categories(locale: I18n.locale)
      raw = config[locale.to_sym] || config[I18n.default_locale.to_sym] || []
      raw.map { |cat| { label: cat[:label], items: cat[:items].map { |i| new(**i) } } }
    end

    def reload!
      @config = nil
    end

    private
      def config
        @config ||= YAML.load_file(config_path).deep_symbolize_keys
      end
  end
end
