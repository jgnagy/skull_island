# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Route resource class
    #
    # @see https://docs.konghq.com/0.14.x/admin-api/#route-object Route API definition
    class Route < Resource
      property :name
      property :methods
      property :paths
      property :protocols,      validate: true
      property :hosts,          validate: true
      property :regex_priority, validate: true
      property :strip_path,     type: :boolean
      property :preserve_host,  type: :boolean
      # The following are 1.0.x only
      # property :snis
      # property :sources
      # property :destinations
      property :service, validate: true, preprocess: true, postprocess: true
      property :created_at, read_only: true, postprocess: true
      property :updated_at, read_only: true, postprocess: true

      # Provides a collection of related {Plugin} instances
      def plugins
        Plugin.where(:route, self, api_client: api_client)
      end

      private

      def postprocess_service(value)
        if value.is_a?(Hash)
          Service.new(
            entity: value,
            lazy: true,
            tainted: false
          )
        else
          value
        end
      end

      def preprocess_service(input)
        if input.is_a?(Hash)
          input
        else
          { 'id' => input.id }
        end
      end

      # Used to validate {#protocols} on set
      def validate_protocols(value)
        value.is_a?(Array) &&                     # Must be an array
          (1..4).cover?(value.size) &&            # Must be exactly 1..4 in size
          value.uniq == value &&                  # Must not have duplicate values
          (value - %w[http https tls tcp]).empty? # Must only contain appropriate protocols
      end

      # Used to validate {#hosts} on set
      def validate_hosts(value)
        # allow only valid hostnames
        value.each do |host|
          return false unless host.match?(host_regex) && !host.match?(/_/)
        end
        true
      end

      # Used to validate {#regex_priority} on set
      def validate_regex_priority(value)
        # only positive Integers are allowed
        value.is_a?(Integer) && (value.positive? || value.zero?)
      end

      # Used to validate {#service} on set
      def validate_service(value)
        # allow either a Service object or a Hash of a specific structure
        value.is_a?(Service) || (value.is_a?(Hash) && value['id'].is_a?(String))
      end
    end
  end
end
