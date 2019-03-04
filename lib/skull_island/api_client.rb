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

    def self.lru_cache
      instance.lru_cache
    end

    def self.server_status
      instance.server_status
    end

    def configure(opts = {})
      # validations
      validate_opts(opts)

      # Set up the client's state
      @server     = opts[:server] || 'http://localhost:8001'
      @username   = opts[:username]
      @password   = opts[:password]
      @cache      = LRUCache.new(1000) # LRU cache of up to 1000 items
      @configured = true
    end
  end
end
