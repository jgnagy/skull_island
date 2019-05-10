# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Upstream Target resource class
    #
    # @see https://docs.konghq.com/1.1.x/admin-api/#target-object Target API definition
    class UpstreamTarget < Resource
      property :target, required: true, validate: true, preprocess: true
      property(
        :upstream,
        required: true, validate: true, preprocess: true, postprocess: true
      )
      property :weight, validate: true
      property :created_at, read_only: true, postprocess: true
      property :tags, validate: true

      def self.batch_import(data, verbose: false, test: false)
        raise(Exceptions::InvalidArguments) unless data.is_a?(Array)

        data.each_with_index do |resource_data, index|
          resource = new
          resource.target = resource_data['target']
          resource.delayed_set(:upstream, resource_data, 'upstream')
          resource.weight = resource_data['weight'] if resource_data['weight']
          resource.tags = resource_data['tags'] if resource_data['tags']
          resource.import_update_or_skip(index: index, verbose: verbose, test: test)
        end
      end

      def self.get(id, options = {})
        if options[:upstream]&.is_a?(Upstream)
          options[:upstream].target(id)
        elsif options[:upstream]
          upstream_opts = options.merge(lazy: true)
          Upstream.get(options[:upstream], upstream_opts).target(id)
        end
      end

      def relative_uri
        upstream ? "#{upstream.relative_uri}/targets/#{id}" : nil
      end

      def save_uri
        upstream ? "#{upstream.relative_uri}/targets" : nil
      end

      def export(options = {})
        hash = { 'target' => target, 'weight' => weight }
        hash['upstream'] = "<%= lookup :upstream, '#{upstream.name}' %>" if upstream
        hash['tags'] = tags if tags
        [*options[:exclude]].each do |exclude|
          hash.delete(exclude.to_s)
        end
        [*options[:include]].each do |inc|
          hash[inc.to_s] = send(inc.to_sym)
        end
        hash.reject { |_, value| value.nil? }
      end

      def modified_existing?
        return false unless new?

        # Find routes of the same name
        same_target_and_upstream = self.class.where(:target, target).and(:upstream, upstream)

        existing = same_target_and_upstream.size == 1 ? same_target_and_upstream.first : nil

        if existing
          @entity['id'] = existing.id
          save
        else
          false
        end
      end

      private

      def preprocess_target(input)
        if input.is_a?(URI)
          "#{input.host}:#{input.port || 8000}"
        else
          input
        end
      end

      def preprocess_upstream(input)
        if input.is_a?(Hash)
          input
        elsif input.is_a?(String)
          { 'id' => input }
        else
          { 'id' => input.id }
        end
      end

      def postprocess_upstream(value)
        if value.is_a?(Hash)
          Upstream.new(
            entity: value,
            lazy: true,
            tainted: false
          )
        else
          value
        end
      end

      # Used to validate {#target} on set
      def validate_target(value)
        # only URIs or specific strings
        value.is_a?(URI) || (
          value.is_a?(String) && value.match?(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{1,5}/)
        )
      end

      # Used to validate #upstream on set
      def validate_upstream(value)
        # allow either a Upstream object or a Hash
        value.is_a?(Upstream) || value.is_a?(Hash) || value.is_a?(String)
      end

      # Used to validate {#weight} on set
      def validate_weight(value)
        # only positive Integers (or zero) are allowed
        value.is_a?(Integer) && (0..1000).cover?(value)
      end
    end
  end
end
