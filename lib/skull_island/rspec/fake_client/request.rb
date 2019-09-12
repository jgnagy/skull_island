# frozen_string_literal: true

module SkullIsland
  module RSpec
    module FakeClient
      # A Fake Rest Client Request for RSpec testing
      class Request
        attr_reader :uri

        def initialize(rest_client, uri)
          @rest_client = rest_client
          @uri = uri
        end

        def hash(data)
          @rest_client.hash(JSON.parse(data))
        end

        def responses
          @rest_client.responses
        end

        def get(_data = nil, _opts = nil)
          responses.dig('get', uri.to_s)
        end

        def post(data = nil, _opts = nil)
          responses.dig('post', uri.to_s + hash(data))
        end

        def patch(data, _opts = nil)
          responses.dig('patch', uri.to_s + hash(data))
        end

        def put(data, _opts = nil)
          responses.dig('put', uri.to_s + hash(data))
        end
      end
    end
  end
end
