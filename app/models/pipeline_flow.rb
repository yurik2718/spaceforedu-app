module PipelineFlow
  STARTING_STAGE = "pago_recibido"
  TERMINAL_STAGE = "completado"
  COTEJO_STAGES  = %w[cotejo_ministerio cotejo_delegacion].freeze

  class << self
    attr_writer :config_path

    def config_path
      @config_path ||= Rails.root.join("config/pipeline.yml")
    end

    def all_stages        = stages.map { _1[:key] }
    def kanban_stages     = stages_for("kanban")
    def horizontal_stages = stages_for("horizontal")
    def checklist_keys    = config[:checklist_keys] || []

    def next_stage(current, country:)
      case current.to_s
      when ""              then STARTING_STAGE
      when "redsara"       then cotejo_for(country)
      when *COTEJO_STAGES  then TERMINAL_STAGE
      when TERMINAL_STAGE  then nil
      else
        seq = linear_sequence
        idx = seq.index(current.to_s)
        idx ? seq[idx + 1] : nil
      end
    end

    def previous_stage(current, country:)
      case current.to_s
      when "", STARTING_STAGE then nil
      when *COTEJO_STAGES     then "redsara"
      when TERMINAL_STAGE     then cotejo_for(country)
      else
        seq = linear_sequence
        idx = seq.index(current.to_s)
        (idx && idx > 0) ? seq[idx - 1] : nil
      end
    end

    def cotejo_for(country)
      if config[:cotejo][:ministerio_countries].include?(country.to_s)
        "cotejo_ministerio"
      else
        config[:cotejo][:default] || "cotejo_delegacion"
      end
    end

    def reload!
      @config = nil
    end

    private
      def stages              = config[:stages]
      def stages_for(display) = stages.select { _1[:display] == display }.map { _1[:key] }
      def linear_sequence     = kanban_stages

      def config
        @config ||= YAML.load_file(config_path).deep_symbolize_keys
      end
  end
end
