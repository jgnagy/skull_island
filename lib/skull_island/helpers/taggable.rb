# frozen_string_literal: true

module SkullIsland
  module Helpers
    # Makes resources _taggable_
    module Taggable
      # Class methods to add when a class is Taggable
      module ClassMethods
        property :tags, validate: true
      end

      # Used to validate {#tags} on set
      def validate_tags(value)
        # allow only valid hostnames
        value.each do |tag|
          return false unless tag.is_a?(String) && tag.match?(/\w_-\.~/)
        end
        true
      end

      def self.included(base)
        base.extend(ClassMethods)
      end
    end
  end
end
