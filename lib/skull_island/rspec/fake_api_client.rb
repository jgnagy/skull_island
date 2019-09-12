# frozen_string_literal: true

module SkullIsland
  module RSpec
    # A Fake API Client for RSpec testing
    class FakeAPIClient < APIClientBase
      def initialize(opts = {})
        # validations
        validate_opts(opts)

        # Set up the client's state
        @server     = opts[:server] || 'http://localhost:8001'
        @username   = opts[:username] || 'admin'
        @password   = opts[:password] || 'admin'
        @cache      = LRUCache.new(100) # LRU cache of up to 100 items
        @configured = true
      end

      def response_for(type, uri, data: nil, response: {})
        connection.response_for(type, uri, data: data, response: response)
      end

      def connection
        @connection ||= FakeRestClient.new
      end
    end
  end
end
