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
      property :retries,            validate: true
      property :protocol,           validate: true, required: true
      property :host,               validate: true, required: true
      property :port,               validate: true, required: true
      property :tls_verify,         type: :boolean
      property :path
      property :connect_timeout,    validate: true
      property :write_timeout,      validate: true
      property :read_timeout,       validate: true
      property :ca_certificates,    validate: true, preprocess: true, postprocess: true
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
          resource.tls_verify = rdata['tls_verify'] if rdata['tls_verify']
          resource.delayed_set(:client_certificate, rdata) if rdata['client_certificate']
          resource.delayed_set(:ca_certificates, rdata) if rdata['ca_certificates']
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

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
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
        if client_certificate&.name
          hash['client_certificate'] = "<%= lookup :certificate, '#{client_certificate.name}' %>"
        elsif client_certificate
          hash['client_certificate'] = { 'id' => client_certificate.id }
        end
        if ca_certificates && !ca_certificates.empty?
          hash['ca_certificates'] = export_ca_certificates
        end
        hash['tls_verify'] = tls_verify if [true, false].include?(tls_verify)
        [*options[:exclude]].each do |exclude|
          hash.delete(exclude.to_s)
        end
        [*options[:include]].each do |inc|
          hash[inc.to_s] = send(inc.to_sym)
        end
        hash.compact
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
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

      def export_ca_certificates
        ca_certificates.map do |cacert|
          cacert.name ? "<%= lookup :ca_certificate, '#{cacert.name}', raw: true %>" : cacert.id
        end
      end

      def postprocess_ca_certificates(value)
        if value.respond_to?(:to_a)
          value.to_a.map do |cacert|
            CACertificate.new(
              entity: { 'id' => cacert },
              lazy: true,
              tainted: false,
              api_client: api_client
            )
          end
        else
          value
        end
      end

      def preprocess_ca_certificates(input)
        input.to_a.map do |cacert|
          cacert.is_a?(String) ? cacert : cacert.id
        end
      end

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
        case input
        when Hash
          input
        when String
          { 'id' => input }
        else
          { 'id' => input.id }
        end
      end

      # Validates {#ca_certificates} on set
      def validate_ca_certificates(value)
        # only Arrays (or Enumarables) are supported
        return false unless value.is_a?(Array) || value.respond_to?(:to_a)

        # Can only contain a array of Strings or CACertificates
        value.to_a.reject { |v| v.is_a?(String) || v.is_a?(CACertificate) }.empty?
      end

      # Used to validate {#client_certificate} on set
      def validate_client_certificate(value)
        # only Strings, Hashes, or Certificates are allowed
        value.is_a?(String) || value.is_a?(Hash) || value.is_a?(Certificate)
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

      # Used to validate {#retries} on set
      def validate_retries(value)
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
