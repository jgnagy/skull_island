# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Plugin resource class
    #
    # @see https://docs.konghq.com/1.1.x/admin-api/#plugin-object Plugin API definition
    class Plugin < Resource
      include Helpers::Meta

      property :name
      property :enabled, type: :boolean
      property :run_on, validate: true
      property :config, validate: true, preprocess: true, postprocess: true
      property :consumer, validate: true, preprocess: true, postprocess: true
      property :route, validate: true, preprocess: true, postprocess: true
      property :service, validate: true, preprocess: true, postprocess: true
      property :created_at, read_only: true, postprocess: true
      property :tags, validate: true, preprocess: true, postprocess: true

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/AbcSize
      def self.batch_import(data, verbose: false, test: false, project: nil, time: nil)
        raise(Exceptions::InvalidArguments) unless data.is_a?(Array)

        known_ids = []

        data.each_with_index do |resource_data, index|
          resource = new
          resource.name = resource_data['name']
          resource.enabled = resource_data['enabled']
          resource.run_on = resource_data['run_on'] if resource_data['run_on']
          resource.delayed_set(:config, resource_data) if resource_data['config']
          resource.tags = resource_data['tags'] if resource_data['tags']
          resource.project = project if project
          resource.import_time = (time || Time.now.utc.to_i) if project
          resource.delayed_set(:consumer, resource_data)
          resource.delayed_set(:route, resource_data)
          resource.delayed_set(:service, resource_data)
          resource.import_update_or_skip(index: index, verbose: verbose, test: test)
          known_ids << resource.id
        end

        cleanup_except(project, known_ids) if project

        known_ids
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/AbcSize

      def self.enabled_names(api_client: APIClient.instance)
        api_client.get("#{relative_uri}/enabled")['enabled_plugins']
      end

      def self.schema(name, api_client: APIClient.instance)
        api_client.get("/schemas/plugins/#{name}")
      end

      def digest_properties
        super.reject { |k| %i[run_on].include? k }
      end

      # rubocop:disable Metrics/AbcSize
      def export(options = {})
        hash = {
          'name' => name,
          'enabled' => enabled?,
          'config' => config.deep_sort.compact
        }
        hash['consumer'] = "<%= lookup :consumer, '#{consumer.username}' %>" if consumer
        hash['route'] = "<%= lookup :route, '#{route.name}' %>" if route
        hash['service'] = "<%= lookup :service, '#{service.name}' %>" if service
        hash['tags'] = tags unless tags.empty?
        [*options[:exclude]].each do |exclude|
          hash.delete(exclude.to_s)
        end
        [*options[:include]].each do |inc|
          hash[inc.to_s] = send(inc.to_sym)
        end
        hash.compact
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def modified_existing?
        return false unless new?

        # Find plugins of the same name
        same_name = self.class.where(:name, name)
        return false if same_name.empty?

        same_name_and_consumer = consumer ? same_name.where(:consumer, consumer) : nil
        same_name_and_route = route ? same_name.where(:route, route) : nil
        same_name_and_service = service ? same_name.where(:service, service) : nil

        existing = if same_name_and_consumer && same_name_and_consumer.size == 1
                     same_name_and_consumer.first
                   elsif same_name_and_route && same_name_and_route.size == 1
                     same_name_and_route.first
                   elsif same_name_and_service && same_name_and_service.size == 1
                     same_name_and_service.first
                   end
        if existing
          @entity['id'] = existing.id
          save
        else
          false
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize

      private

      def preprocess_config(input)
        input.deep_sort
      end

      def postprocess_config(value)
        value.deep_sort.prune.compact
      end

      def postprocess_consumer(value)
        case value
        when Hash
          Consumer.new(
            entity: value,
            lazy: true,
            tainted: false,
            api_client: api_client
          )
        when String
          Consumer.new(
            entity: { 'id' => value },
            lazy: true,
            tainted: false,
            api_client: api_client
          )
        else
          value
        end
      end

      def preprocess_consumer(input)
        case input
        when Consumer
          { 'id' => input.id }
        else
          input
        end
      end

      def postprocess_route(value)
        case value
        when Hash
          Route.new(
            entity: value,
            lazy: true,
            tainted: false,
            api_client: api_client
          )
        when String
          Route.new(
            entity: { 'id' => value },
            lazy: true,
            tainted: false,
            api_client: api_client
          )
        else
          value
        end
      end

      def preprocess_route(input)
        case input
        when Route
          { 'id' => input.id }
        else
          input
        end
      end

      def postprocess_service(value)
        case value
        when Hash
          Service.new(
            entity: value,
            lazy: true,
            tainted: false,
            api_client: api_client
          )
        when String
          Service.new(
            entity: { 'id' => value },
            lazy: true,
            tainted: false,
            api_client: api_client
          )
        else
          value
        end
      end

      def preprocess_service(input)
        case input
        when Service
          { 'id' => input.id }
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
        value.is_a?(Consumer) || value.is_a?(Hash)
      end

      # Used to validate {#route} on set
      def validate_route(value)
        # allow either a Route object or a Hash of a specific structure
        value.is_a?(Route) || value.is_a?(Hash)
      end

      # Used to validate {#run_on} on set
      def validate_run_on(value)
        # allow either a Route object or a Hash of a specific structure
        %w[first second all].include?(value)
      end

      # Used to validate {#service} on set
      def validate_service(value)
        # allow either a Service object or a Hash of a specific structure
        value.is_a?(Service) || value.is_a?(Hash)
      end
    end
  end
end
