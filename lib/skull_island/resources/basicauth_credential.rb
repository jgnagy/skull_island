# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The BasicauthCredential resource class
    #
    # @see https://docs.konghq.com/hub/kong-inc/basic-auth/ Basic-Auth API definition
    class BasicauthCredential < Resource
      attr_accessor :hashed_password

      property :username, required: true, validate: true
      property :password, validated: true, preprocess: true, postprocess: true
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
          resource.delayed_set(:username, resource_data, 'username')
          resource.delayed_set(:password, resource_data, 'password') if resource_data['password']
          resource.delayed_set(:consumer, resource_data, 'consumer')
          resource.import_update_or_skip(index: index, verbose: verbose, test: test)
          known_ids << resource.id
        end

        known_ids
      end

      def self.relative_uri
        'basic-auths'
      end

      def relative_uri
        consumer ? "#{consumer.relative_uri}/basic-auth/#{id}" : nil
      end

      def save_uri
        consumer ? "#{consumer.relative_uri}/basic-auth" : nil
      end

      def digest
        Digest::MD5.hexdigest(
          if new? && !password.match?(/^hash{.+}$/)
            hashed_pass = Digest::SHA1.hexdigest((password || '') + consumer.id)
            "#{username}:hash{#{hashed_pass}}"
          else
            "#{username}:#{password}"
          end
        )
      end

      def export(options = {})
        hash = { 'username' => username, 'password' => password }
        hash['consumer'] = "<%= lookup :consumer, '#{consumer.username}' %>" if consumer
        [*options[:exclude]].each do |exclude|
          hash.delete(exclude.to_s)
        end
        [*options[:include]].each do |inc|
          hash[inc.to_s] = send(inc.to_sym)
        end
        hash.reject { |_, value| value.nil? }
      end

      # Credentials can't be updated, only deleted then created
      def modified_existing?
        return false unless new?

        # Find credentials of the same username
        basic_auths = consumer.credentials['basic-auth']
        return false unless basic_auths

        same_username = basic_auths.where(:username, username)

        existing = same_username.size == 1 ? same_username.first : nil
        # Need to destroy the old one then save the new one...
        existing ? existing.destroy && save : false
      end

      def project
        consumer ? consumer.project : nil
      end

      def <=>(other)
        if id
          if id < other.id
            -1
          elsif id > other.id
            1
          elsif id == other.id
            0
          else
            raise Exceptions::InvalidArguments
          end
        else
          digest <=> other.digest
        end
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

      def postprocess_password(value)
        hashed_password || !new? ? "hash{#{value}}" : value
      end

      def preprocess_password(input)
        if input.match?(/^hash{.+}$/)
          @hashed_password = true
          input.match(/^hash{(.+)}$/)[1]
        else
          input
        end
      end

      # Used to validate {#consumer} on set
      def validate_consumer(value)
        # allow either a Consumer object or a Hash
        value.is_a?(Consumer) || value.is_a?(Hash)
      end

      # Used to validate {#password} on set
      def validate_password(value)
        # allow a String
        value.is_a?(String)
      end

      # Used to validate {#username} on set
      def validate_username(value)
        # allow a String
        value.is_a?(String)
      end
    end
  end
end
