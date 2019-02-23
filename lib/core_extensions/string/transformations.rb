# frozen_string_literal: true

module CoreExtensions
  module String
    # Monkey-patches for String to add some simple missing transformations
    module Transformations
      # Convert CamelCase to underscored_text
      # @return [String]
      def to_underscore
        gsub(/::/, '/')
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .tr('-', '_')
          .downcase
      end

      # Convert underscored_text to CamelCase
      # @return [String]
      def to_camel
        split('_').map(&:capitalize).join
      end

      # Attempt to guess a more human-like view of a string
      # @return [String]
      def humanize
        gsub(/_id$/, '').tr('_', ' ').capitalize
      end
    end
  end
end
