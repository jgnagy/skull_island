# frozen_string_literal: true

module SkullIsland
  module Helpers
    # Simple helper methods for the API Client
    module APIClient
      def about_service
        get '/'
      end

      def server_status
        get '/status'
      end

      def cache(key)
        symbolized_key = key.to_sym
        if !@cache.has?(symbolized_key) && block_given?
          result = yield(self)
          @cache.store(symbolized_key, result)
        elsif !@cache.has?(symbolized_key)
          return nil
        end
        @cache.retrieve(symbolized_key)
      end

      def invalidate_cache_for(key)
        symbolized_key = key.to_sym
        @cache.invalidate(symbolized_key)
      end

      def lru_cache
        @cache
      end

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
