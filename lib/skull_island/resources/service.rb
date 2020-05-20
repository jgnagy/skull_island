# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Service resource class
    #
    # @see https://docs.konghq.com/1.1.x/admin-api/#service-object Service API definition
    class Service < Resource
      include Helpers::Meta

      property :name
      property :retries
      property :protocol,           validate: true, required: true
      property :host,               validate: true, required: true
      property :port,               validate: true, required: true
      property :path
      property :connect_timeout,    validate: true
      property :write_timeout,      validate: true
      property :read_timeout,       validate: true
      property :client_certificate, validate: true, preprocess: true, postprocess: true
      property :created_at, read_only: true, postprocess: true
      property :updated_at, read_only: true, postprocess: true
      property :tags, validate: true, preprocess: true, postprocess: true

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/AbcSize
      def self.batch_import(data, verbose: false, test: false, project: nil, time: nil)
        raise(Exceptions::InvalidArguments) unless data.is_a?(Array)

        known_ids = []

        data.each_with_index do |rdata, index|
          resource = new
          resource.name = rdata['name']
          resource.retries = rdata['retries'] if rdata['retries']
          resource.protocol = rdata['protocol']
          resource.delayed_set(:host, rdata)
          resource.delayed_set(:port, rdata)
          resource.path = rdata['path'] if rdata['path']
          resource.connect_timeout = rdata['connect_timeout'] if rdata['connect_timeout']
          resource.write_timeout = rdata['write_timeout'] if rdata['write_timeout']
          resource.read_timeout = rdata['read_timeout'] if rdata['read_timeout']
          resource.delayed_set(:client_certificate, rdata) if rdata['client_certificate']
          resource.tags = rdata['tags'] if rdata['tags']
          resource.project = project if project
          resource.import_time = (time || Time.now.utc.to_i) if project
          resource.import_update_or_skip(index: index, verbose: verbose, test: test)
          known_ids << resource.id

          previous_routes = resource.routes.dup

          added_routes = Route.batch_import(
            (rdata['routes'] || []).map { |r| r.merge('service' => { 'id' => resource.id }) },
            verbose: verbose,
            test: test,
            project: project,
            time: time,
            cleanup: false
          )

          Route.cleanup_except(project, added_routes, previous_routes)
        end

        cleanup_except(project, known_ids) if project

        known_ids
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/AbcSize

      # Convenience method to add routes
      def add_route!(details)
        r = details.is_a?(Route) ? details : Route.from_hash(details, api_client: api_client)

        r.service = self
        r.save
      end

      def destroy
        routes.each(&:destroy)
        super
      end

      # Provides a collection of related {Route} instances
      def routes
        Route.where(:service, self, api_client: api_client)
      end

      # Provides a collection of related {Plugin} instances
      def plugins
        Plugin.where(:service, self, api_client: api_client)
      end

      # rubocop:disable Metrics/AbcSize
      def export(options = {})
        hash = {
          'name' => name,
          'retries' => retries,
          'protocol' => protocol,
          'host' => host,
          'port' => port,
          'path' => path,
          'connect_timeout' => connect_timeout,
          'write_timeout' => write_timeout,
          'read_timeout' => read_timeout
        }
        hash['routes'] = routes.collect { |route| route.export(exclude: 'service') }
        hash['tags'] = tags unless tags.empty?
        hash['client_certificate'] = client_certificate if client_certificate
        [*options[:exclude]].each do |exclude|
          hash.delete(exclude.to_s)
        end
        [*options[:include]].each do |inc|
          hash[inc.to_s] = send(inc.to_sym)
        end
        hash.reject { |_, value| value.nil? }
      end
      # rubocop:enable Metrics/AbcSize

      def modified_existing?
        return false unless new?

        # Find services of the same name
        same_name = self.class.where(:name, name)

        existing = same_name.size == 1 ? same_name.first : nil

        if existing
          @entity['id'] = existing.id
          save
        else
          false
        end
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

      def postprocess_client_certificate(value)
        if value.is_a?(Hash)
          Certificate.new(
            entity: value,
            lazy: true,
            tainted: false,
            api_client: api_client
          )
        else
          value
        end
      end

      def preprocess_client_certificate(input)
        if input.is_a?(Hash)
          input
        else
          { 'id' => input.id }
        end
      end

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

      # Used to validate {#connect_timeout} on set
      def validate_connect_timeout(value)
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
