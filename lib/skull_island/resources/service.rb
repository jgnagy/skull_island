# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Service resource class
    #
    # @see https://docs.konghq.com/0.14.x/admin-api/#service-object Service API definition
    class Service < Resource
      property :name
      property :retries
      property :protocol,           validate: true, required: true
      property :host,               validate: true, required: true
      property :port,               validate: true, required: true
      property :path
      property :connection_timeout, validate: true
      property :write_timeout,      validate: true
      property :read_timeout,       validate: true
      property :created_at, read_only: true, postprocess: true
      property :updated_at, read_only: true, postprocess: true

      # Convenience method to add routes
      def add_route!(details)
        r = details.is_a?(Route) ? details : Route.from_hash(details)

        r.service = self
        r.save
      end

      # Provides a collection of related {Route} instances
      def routes
        Route.where(:service, self, api_client: api_client)
      end

      # Provides a collection of related {Plugin} instances
      def plugins
        Plugin.where(:service, self, api_client: api_client)
      end

      def url=(uri_or_string)
        uri_data = URI(uri_or_string)
        self.protocol = uri_data.scheme
        self.host = uri_data.host
        self.port = uri_data.port
      end

      def url
        u = URI('')
        u.scheme = protocol
        u.host = host
        u.port = port unless [80, 443].include? port
        u.to_s
      end

      private

      # Used to validate {#protocol} on set
      def validate_protocol(value)
        # only HTTP and HTTPS are allowed
        %w[http https].include? value
      end

      # Used to validate {#host} on set
      def validate_host(value)
        # allow only valid hostnames
        value.match?(host_regex) && !value.match?(/_/)
      end

      # Used to validate {#port} on set
      def validate_port(value)
        # only positive Integers of the right value are allowed
        value.is_a?(Integer) && value.positive? && (1...65_535).cover?(value)
      end

      # Used to validate {#connection_timeout} on set
      def validate_connection_timeout(value)
        # only positive Integers are allowed
        value.is_a?(Integer) && value.positive?
      end

      # Used to validate {#write_timeout} on set
      def validate_write_timeout(value)
        # only positive Integers are allowed
        value.is_a?(Integer) && value.positive?
      end

      # Used to validate {#read_timeout} on set
      def validate_read_timeout(value)
        # only positive Integers are allowed
        value.is_a?(Integer) && value.positive?
      end
    end
  end
end
