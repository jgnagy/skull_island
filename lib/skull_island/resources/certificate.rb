# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Certificate resource class
    #
    # @see https://docs.konghq.com/1.1.x/admin-api/#certificate-object Certificate API definition
    class Certificate < Resource
      property :cert, required: true, validate: true
      property :key, required: true, validate: true
      property :snis, validate: true
      property :created_at, read_only: true, postprocess: true
      property :tags, validate: true

      def self.batch_import(data, verbose: false, test: false)
        raise(Exceptions::InvalidArguments) unless data.is_a?(Array)

        data.each_with_index do |resource_data, index|
          resource = new
          resource.cert = resource_data['cert']
          resource.key = resource_data['key']
          resource.snis = resource_data['snis'] if resource_data['snis']
          resource.tags = resource_data['tags'] if resource_data['tags']
          resource.import_update_or_skip(index: index, verbose: verbose, test: test)
        end
      end

      def export(options = {})
        hash = { 'cert' => cert, 'key' => key }
        hash['snis'] = snis if snis && !snis.empty?
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

        # Find certs of the same cert and key
        same_key = self.class.where(:key, key)

        existing = same_key.size == 1 ? same_key.first : nil

        if existing
          @entity['id'] = existing.id
          save
        else
          false
        end
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
