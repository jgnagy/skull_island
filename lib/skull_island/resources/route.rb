# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Route resource class
    #
    # @see https://docs.konghq.com/1.4.x/admin-api/#route-object Route API definition
    class Route < Resource
      include Helpers::Meta

      property :name
      property :methods
      property :paths
      property :protocols,      validate: true
      property :headers,        validate: true
      property :hosts,          validate: true
      property :https_redirect_status_code, validate: true
      property :regex_priority, validate: true
      property :strip_path,     type: :boolean
      property :preserve_host,  type: :boolean
      property :snis,           validate: true
      property :path_handling,  validate: true
      property :sources
      property :destinations
      property :service, validate: true, preprocess: true, postprocess: true
      property :created_at, read_only: true, postprocess: true
      property :updated_at, read_only: true, postprocess: true
      property :tags, validate: true, preprocess: true, postprocess: true

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Layout/LineLength
      def self.batch_import(data, verbose: false, test: false, project: nil, time: nil, cleanup: true)
        raise(Exceptions::InvalidArguments) unless data.is_a?(Array)

        known_ids = []

        data.each_with_index do |rdata, index|
          resource = new
          resource.name = rdata['name']
          resource.methods = rdata['methods'] if rdata['methods']
          resource.paths = rdata['paths'] if rdata['paths']
          resource.protocols = rdata['protocols'] if rdata['protocols']
          resource.delayed_set(:hosts, rdata) if rdata['hosts']
          resource.delayed_set(:headers, rdata) if rdata['headers']
          if rdata['https_redirect_status_code']
            resource.https_redirect_status_code = rdata['https_redirect_status_code']
          end
          resource.regex_priority = rdata['regex_priority'] if rdata['regex_priority']
          resource.strip_path = rdata['strip_path'] unless rdata['strip_path'].nil?
          resource.preserve_host = rdata['preserve_host'] unless rdata['preserve_host'].nil?
          resource.delayed_set(:snis, rdata) if rdata['snis']
          resource.tags = rdata['tags'] if rdata['tags']
          resource.project = project if project
          resource.import_time = (time || Time.now.utc.to_i) if project
          resource.delayed_set(:service, rdata)
          resource.import_update_or_skip(index: index, verbose: verbose, test: test)
          known_ids << resource.id
        end

        cleanup_except(project, known_ids) if project && cleanup

        known_ids
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Layout/LineLength

      # Provides a collection of related {Plugin} instances
      def plugins
        Plugin.where(:route, self, api_client: api_client)
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/AbcSize
      def export(options = {})
        hash = {
          'name' => name,
          'methods' => methods,
          'paths' => paths,
          'protocols' => protocols,
          'hosts' => hosts,
          'https_redirect_status_code' => https_redirect_status_code,
          'regex_priority' => regex_priority,
          'strip_path' => strip_path?,
          'preserve_host' => preserve_host?
        }
        hash['service'] = "<%= lookup :service, '#{service.name}' %>" if service
        hash['snis'] = snis if snis && !snis.empty?
        hash['headers'] = headers if headers && !headers.empty?
        hash['tags'] = tags unless tags.empty?
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

        # Find routes of the same name and service
        same_name_and_service = self.class.where(:name, name).and(:service, service)

        existing = same_name_and_service.size == 1 ? same_name_and_service.first : nil

        if existing
          @entity['id'] = existing.id
          save
        else
          false
        end
      end

      private

      def postprocess_service(value)
        if value.is_a?(Hash)
          Service.new(
            entity: value,
            lazy: true,
            tainted: false,
            api_client: api_client
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

      # Used to validate {#path_handling} on set
      def validate_path_handling(value)
        valid_values = %w[v0 v1]
        valid_values.include?(value)
      end

      # Used to validate {#protocols} on set
      def validate_protocols(value)
        valid_protos = %w[http https tls tcp grpc grpcs]
        value.is_a?(Array) &&           # Must be an array
          (1..4).cover?(value.size) &&  # Must be exactly 1..4 in size
          value.uniq == value &&        # Must not have duplicate values
          (value - valid_protos).empty? # Must only contain appropriate protocols
      end

      # Validates the {#headers} on set
      def validate_headers(value)
        value.is_a?(Hash) &&
          value.keys.map(&:class).uniq == [String] &&
          value.values.map(&:class).uniq == [Array] &&
          value.values.map { |v| v.map(&:class) }.flatten.uniq == [String]
      end

      # Used to validate {#hosts} on set
      def validate_hosts(value)
        # allow only valid hostnames
        value.each do |host|
          return false unless host.match?(host_regex) && !host.match?(/_/)
        end
        true
      end

      # Validates the {#https_redirect_status_code} on set
      def validate_https_redirect_status_code(value)
        value.is_a?(Integer) && value <= 599 && value >= 100
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

      # Used to validate {#snis} on set
      def validate_snis(value)
        return false unless value.is_a?(Array)

        # allow only valid hostnames
        value.each do |sni|
          return false unless sni.match?(host_regex) && !sni.match?(/_/)
        end
        true
      end
    end
  end
end
