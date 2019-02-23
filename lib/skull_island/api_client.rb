# frozen_string_literal: true

module SkullIsland
  # The API Client Singleton class
  class APIClient < APIClientBase
    include Singleton

    def self.configure(opts = {})
      instance.configure(opts)
    end

    def self.about_service
      instance.about_service
    end

    def configure(opts = {})
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
