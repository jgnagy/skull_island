# frozen_string_literal: true

module SkullIsland
  module Helpers
    # Simple helper methods for the API Client
    module APIClient
      # Substitute characters with their JSON-supported versions
      # @return [String]
      def json_escape(string)
        json_escape = {
          '&' => '\u0026',
          '>' => '\u003e',
          '<' => '\u003c',
          '%' => '\u0025',
          "\u2028" => '\u2028',
          "\u2029" => '\u2029'
        }
        json_escape_regex = /[\u2028\u2029&><%]/u

        string.to_s.gsub(json_escape_regex, json_escape)
      end

      # Provides access to the "raw" underlying rest-client
      # @return [RestClient::Resource]
      def raw
        connection
      end

      # The API Client version (uses Semantic Versioning)
      # @return [String]
      def version
        VERSION
      end
    end
  end
end
