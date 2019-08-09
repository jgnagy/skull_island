# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The JWTCredential resource class
    #
    # @see https://docs.konghq.com/hub/kong-inc/jwt/ JWT Authentication details
    class JWTCredential < Resource
      property :algorithm, required: true, validate: true
      property :key, validate: true
      property :secret, validated: true
      property :rsa_public_key, validated: true
      property(
        :consumer,
        required: true, validate: true, preprocess: true, postprocess: true
      )
      property :created_at, read_only: true, postprocess: true

      def self.batch_import(data, verbose: false, test: false)
        raise(Exceptions::InvalidArguments) unless data.is_a?(Array)

        known_ids = []

        data.each_with_index do |resource_data, index|
          resource = new
          resource.algorithm = resource_data['algorithm']
          resource.delayed_set(:key, resource_data, 'key') if resource_data['key']
          resource.delayed_set(:secret, resource_data, 'secret') if resource_data['secret']
          if resource_data['rsa_public_key']
            resource.delayed_set(:rsa_public_key, resource_data, 'rsa_public_key')
          end
          resource.delayed_set(:consumer, resource_data, 'consumer')
          resource.import_update_or_skip(index: index, verbose: verbose, test: test)
          known_ids << resource.id
        end

        known_ids
      end

      def self.relative_uri
        'jwts'
      end

      def relative_uri
        consumer ? "#{consumer.relative_uri}/jwt/#{id}" : nil
      end

      def save_uri
        consumer ? "#{consumer.relative_uri}/jwt" : nil
      end

      def export(options = {})
        hash = { 'algorithm' => algorithm }
        hash['key'] = key if key
        hash['secret'] = secret if secret
        hash['rsa_public_key'] = rsa_public_key if rsa_public_key
        hash['consumer'] = "<%= lookup :consumer, '#{consumer.username}' %>" if consumer
        [*options[:exclude]].each do |exclude|
          hash.delete(exclude.to_s)
        end
        [*options[:include]].each do |inc|
          hash[inc.to_s] = send(inc.to_sym)
        end
        hash.reject { |_, value| value.nil? }
      end

      # Keys can't be updated, only created or deleted
      def modified_existing?
        false
      end

      def project
        consumer ? consumer.project : nil
      end

      private

      def postprocess_consumer(value)
        if value.is_a?(Hash)
          Consumer.new(
            entity: value,
            lazy: true,
            tainted: false
          )
        else
          value
        end
      end

      def preprocess_consumer(input)
        if input.is_a?(Hash)
          input
        else
          { 'id' => input.id }
        end
      end

      # Used to validate {#consumer} on set
      def validate_consumer(value)
        # allow either a Consumer object or a Hash
        value.is_a?(Consumer) || value.is_a?(Hash)
      end

      # Used to validate {#algorithm} on set
      def validate_algorithm(value)
        # allow a String
        %w[HS256 HS384 HS512 RS256 ES256].include? value
      end

      # Used to validate {#key} on set
      def validate_key(value)
        # allow a String
        value.is_a?(String)
      end

      # Used to validate {#secret} on set
      def validate_secret(value)
        # allow a String
        value.is_a?(String)
      end

      # Used to validate {#rsa_public_key} on set
      def validate_rsa_public_key(value)
        # allow a String
        value.is_a?(String)
      end
    end
  end
end
