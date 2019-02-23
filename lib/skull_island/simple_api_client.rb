# frozen_string_literal: true

module SkullIsland
  # The Simple API Client class
  class SimpleAPIClient < APIClientBase
    def initialize(opts = {})
      # validations
      validate_opts(opts)

      # Set up the client's state
      @server     = opts[:server] || 'http://localhost:8001'
      @username   = opts[:username]
      @password   = opts[:password]
      @configured = true
    end
  end
end
