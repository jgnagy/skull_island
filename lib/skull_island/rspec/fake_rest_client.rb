# frozen_string_literal: true

module SkullIsland
  module RSpec
    # A Fake Rest Client for RSpec testing
    class FakeRestClient
      attr_reader :responses

      def initialize
        @responses = {}
      end

      def hash(data)
        if data
          Digest::MD5.hexdigest(data.sort.to_s)
        else
          ''
        end
      end

      def response_for(type, uri, data: nil, response: {})
        @responses[type.to_s] ||= {}
        key = data ? uri.to_s + hash(data) : uri.to_s
        @responses[type.to_s][key] = JSON.dump(response)
      end

      def [](uri)
        FakeClient::Request.new(self, uri)
      end
    end
  end
end
