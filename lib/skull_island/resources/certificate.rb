# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Certificate resource class
    #
    # @see https://docs.konghq.com/0.14.x/admin-api/#certificate-object Certificate API definition
    class Certificate < Resource
      property :cert, required: true, validate: true
      property :key, required: true, validate: true
      property :snis, validate: true
      property :created_at, read_only: true, postprocess: true

      # rubocop:disable Metrics/PerceivedComplexity
      def self.batch_import(data, verbose: false)
        raise(Exceptions::InvalidArguments) unless data.is_a?(Array)

        data.each_with_index do |resource_data, index|
          resource = new
          resource.cert = resource_data['cert']
          resource.key = resource_data['key']
          resource.snis = resource_data['snis'] if resource_data['snis']
          if resource.find_by_digest
            puts "[INFO] Skipping #{resource.class} index #{index} (#{resource.id})" if verbose
          elsif resource.save
            puts "[INFO] Saved #{resource.class} index #{index} (#{resource.id})" if verbose
          else
            puts "[ERR] Failed to save #{resource.class} index #{index}"
          end
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity

      def to_hash(options = {})
        hash = { 'cert' => cert, 'key' => key, 'snis' => snis }
        [*options[:exclude]].each do |exclude|
          hash.delete(exclude.to_s)
        end
        [*options[:include]].each do |inc|
          hash[inc.to_s] = send(:inc)
        end
        hash.reject { |_, value| value.nil? }
      end

      private

      # Used to validate {#cert} on set
      def validate_cert(value)
        # only String is allowed
        value.is_a?(String)
      end

      # Used to validate {#key} on set
      def validate_key(value)
        # only String is allowed
        value.is_a?(String)
      end

      # Used to validate {#snis} on set
      def validate_snis(value)
        # only Array is allowed
        value.is_a?(Array)
      end
    end
  end
end
