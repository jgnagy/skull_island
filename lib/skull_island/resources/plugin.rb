# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Plugin resource class
    #
    # @see https://docs.konghq.com/0.14.x/admin-api/#plugin-object Plugin API definition
    class Plugin < Resource
      property :name
      property :enabled, type: :boolean
      property :run_on
      property :sources
      property :config, validate: true
      property :consumer_id, validate: true, preprocess: true, postprocess: true, as: :consumer
      property :route_id, validate: true, preprocess: true, postprocess: true, as: :route
      property :service_id, validate: true, preprocess: true, postprocess: true, as: :service
      property :created_at, read_only: true, postprocess: true

      def self.enabled_names
        APIClient.instance.get("#{relative_uri}/enabled")['enabled_plugins']
      end

      def self.schema(name)
        APIClient.instance.get("#{relative_uri}/schema/#{name}")
      end

      private

      # TODO: 1.0.x requires refactoring as `consumer_id` becomes `consumer`
      def postprocess_consumer_id(value)
        if value.is_a?(Hash)
          Consumer.new(
            entity: value,
            lazy: true,
            tainted: false
          )
        elsif value.is_a?(String)
          Consumer.new(
            entity: { 'id' => value },
            lazy: true,
            tainted: false
          )
        else
          value
        end
      end

      # TODO: 1.0.x requires refactoring as `consumer_id` becomes `consumer`
      def preprocess_consumer_id(input)
        if input.is_a?(Hash)
          input['id']
        elsif input.is_a?(Consumer)
          input.id
        else
          input
        end
      end

      # TODO: 1.0.x requires refactoring as `route_id` becomes `route`
      def postprocess_route_id(value)
        if value.is_a?(Hash)
          Route.new(
            entity: value,
            lazy: true,
            tainted: false
          )
        elsif value.is_a?(String)
          Route.new(
            entity: { 'id' => value },
            lazy: true,
            tainted: false
          )
        else
          value
        end
      end

      # TODO: 1.0.x requires refactoring as `route_id` becomes `route`
      def preprocess_route_id(input)
        if input.is_a?(Hash)
          input['id']
        elsif input.is_a?(Route)
          input.id
        else
          input
        end
      end

      # TODO: 1.0.x requires refactoring as `service_id` becomes `service`
      def postprocess_service_id(value)
        if value.is_a?(Hash)
          Service.new(
            entity: value,
            lazy: true,
            tainted: false
          )
        elsif value.is_a?(String)
          Service.new(
            entity: { 'id' => value },
            lazy: true,
            tainted: false
          )
        else
          value
        end
      end

      # TODO: 1.0.x requires refactoring as `service_id` becomes `service`
      def preprocess_service_id(input)
        if input.is_a?(Hash)
          input['id']
        elsif input.is_a?(Service)
          input.id
        else
          input
        end
      end

      # Used to validate {#config} on set
      def validate_config(value)
        # only Hashes are allowed
        value.is_a?(Hash)
      end

      # Used to validate {#consumer} on set
      def validate_consumer(value)
        # allow either a Consumer object or a Hash of a specific structure
        value.is_a?(Consumer) || (value.is_a?(Hash) && value['id'].is_a?(String))
      end

      # Used to validate {#route} on set
      def validate_route(value)
        # allow either a Route object or a Hash of a specific structure
        value.is_a?(Route) || (value.is_a?(Hash) && value['id'].is_a?(String))
      end

      # Used to validate {#service} on set
      def validate_service(value)
        # allow either a Service object or a Hash of a specific structure
        value.is_a?(Service) || (value.is_a?(Hash) && value['id'].is_a?(String))
      end
    end
  end
end
