# frozen_string_literal: true

module CoreExtensions
  module Hash
    # Monkey-patches for Hash to add some recursive pruning options
    module Pruning
      # Recursively strips empty and nil elements from a Hash
      # @return [Hash]
      def prune
        newhash = {}

        each do |k, v|
          if v.is_a?(Hash)
            newvalue = v.prune
            newhash[k] = newvalue unless newvalue.empty?
          elsif v.respond_to?(:empty?)
            newhash[k] = v unless v.empty?
          else
            newhash[k] = v unless v.nil?
          end
        end

        newhash
      end
    end
  end
end
