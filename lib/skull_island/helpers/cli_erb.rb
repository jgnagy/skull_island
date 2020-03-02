# frozen_string_literal: true

module SkullIsland
  module Helpers
    # Performs a simple, first pass ERb preprocess on the entire input file for the CLI
    module CliErb
      def erb_preprocess(input)
        warn '[INFO] Preprocessing template' if options['verbose']
        # rubocop:disable Security/Eval
        eval(Erubi::Engine.new(input).src)
        # rubocop:enable Security/Eval
      end

      # At this phase, we want to leave this alone...
      def lookup(type, value, raw = false)
        "<%= lookup :#{type}, '#{value}', #{raw} %>"
      end
    end
  end
end
