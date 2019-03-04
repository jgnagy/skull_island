# frozen_string_literal: true

require 'digest'

module SkullIsland
  module RSpec
    # A Fake API Client for RSpec testing
    class FakeAPIClient
      attr_reader :server, :base_uri
      attr_accessor :username, :password

      include Validations::APIClient
      include Helpers::APIClient

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

      def hash(data)
        if data
          Digest::MD5.hexdigest(data.sort.to_s)
        else
          ''
        end
      end

      def response_for(type, uri, data: nil, response: {})
        @responses ||= {}
        @responses[type.to_s] ||= {}
        key = data ? uri.to_s + hash(data) : uri.to_s
        @responses[type.to_s][key] = response
      end

      def get(uri, _data = nil)
        @responses ||= {}
        @responses.dig('get', uri.to_s)
      end

      def post(uri, data = nil)
        @responses ||= {}
        @responses.dig('post', uri.to_s + hash(data))
      end

      def patch(uri, data)
        @responses ||= {}
        @responses.dig('patch', uri.to_s + hash(data))
      end

      def put(uri, data)
        @responses ||= {}
        @responses.dig('put', uri.to_s + hash(data))
      end
    end
  end
end
