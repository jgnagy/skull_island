# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The ACL resource class
    #
    # @see https://docs.konghq.com/hub/kong-inc/acl/ ACL API definition
    class AccessControlList < Resource
      property :group, validate: true
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
          resource.delayed_set(:group, resource_data)
          resource.delayed_set(:consumer, resource_data)
          resource.import_update_or_skip(index: index, verbose: verbose, test: test)
          known_ids << resource.id
        end

        known_ids
      end

      def self.relative_uri
        'acls'
      end

      def relative_uri
        consumer ? "#{consumer.relative_uri}/acls/#{id}" : nil
      end

      def save_uri
        consumer ? "#{consumer.relative_uri}/acls" : nil
      end

      def export(options = {})
        hash = { 'group' => group }
        hash['consumer'] = "<%= lookup :consumer, '#{consumer.username}' %>" if consumer
        [*options[:exclude]].each do |exclude|
          hash.delete(exclude.to_s)
        end
        [*options[:include]].each do |inc|
          hash[inc.to_s] = send(inc.to_sym)
        end
        hash.compact
      end

      # Keys can't be updated, only created or deleted
      def modified_existing?
        false
      end

      def project
        consumer&.project
      end

      private

      def postprocess_consumer(value)
        if value.is_a?(Hash)
          Consumer.new(
            entity: value,
            lazy: true,
            tainted: false,
            api_client: api_client
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

      # Used to validate {#group} on set
      def validate_group(value)
        # allow a String
        value.is_a?(String)
      end
    end
  end
end
