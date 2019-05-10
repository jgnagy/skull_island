# frozen_string_literal: true

module SkullIsland
  # The API Client Base class
  class APIClientBase
    attr_reader :server, :base_uri
    attr_accessor :username, :password

    include Validations::APIClient
    include Helpers::APIClient

    def api_uri
      @api_uri ||= URI.parse(server)
      @api_uri.path = base_uri if base_uri
      @api_uri
    end

    def authenticated?
      raise Exceptions::APIClientNotConfigured unless configured?

      @username && @password ? true : false
    end

    def configured?
      @configured ? true : false
    end

    def json_headers
      { content_type: :json, accept: :json }
    end

    def get(uri, data = nil)
      client_action do |client|
        # TODO: Support the API's pagination through the "next" top-level key
        if data
          JSON.parse client[uri].get(json_headers.merge(params: data))
        else
          JSON.parse client[uri].get(json_headers)
        end
      end
    end

    def post(uri, data = nil)
      client_action do |client|
        if data
          JSON.parse client[uri].post(json_escape(data.to_json), json_headers)
        else
          JSON.parse client[uri].post(nil, json_headers)
        end
      end
    end

    def patch(uri, data)
      client_action do |client|
        response = client[uri].patch(json_escape(data.to_json), json_headers)
        if response && !response.empty?
          JSON.parse(response)
        else
          true
        end
      end
    end

    def put(uri, data)
      client_action do |client|
        client[uri].put(json_escape(data.to_json), json_headers)
      end
    end

    private

    def client_action
      raise Exceptions::APIClientNotConfigured unless configured?

      yield connection
    end

    # Don't bother creating a connection until we need one
    def connection
      @connection ||= if authenticated?
                        RestClient::Resource.new(api_uri.to_s, @username, @password)
                      else
                        RestClient::Resource.new(api_uri.to_s)
                      end
    end
  end
end
