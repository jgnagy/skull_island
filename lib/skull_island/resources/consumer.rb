# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Consumer resource class
    #
    # @see https://docs.konghq.com/1.1.x/admin-api/#consumer-object Consumer API definition
    class Consumer < Resource
      property :username
      property :custom_id
      property :created_at, read_only: true, postprocess: true
      property :tags, validate: true

      def self.batch_import(data, verbose: false, test: false)
        raise(Exceptions::InvalidArguments) unless data.is_a?(Array)

        data.each_with_index do |resource_data, index|
          resource = new
          resource.username = resource_data['username']
          resource.custom_id = resource_data['custom_id']
          resource.tags = resource_data['tags'] if resource_data['tags']
          resource.import_update_or_skip(index: index, verbose: verbose, test: test)

          BasicauthCredential.batch_import(
            (
              resource_data.dig('credentials', 'basic-auth') || []
            ).map { |t| t.merge('consumer' => { 'id' => resource.id }) },
            verbose: verbose,
            test: test
          )

          JWTCredential.batch_import(
            (
              resource_data.dig('credentials', 'jwt') || []
            ).map { |t| t.merge('consumer' => { 'id' => resource.id }) },
            verbose: verbose,
            test: test
          )

          KeyauthCredential.batch_import(
            (
              resource_data.dig('credentials', 'key-auth') || []
            ).map { |t| t.merge('consumer' => { 'id' => resource.id }) },
            verbose: verbose,
            test: test
          )
        end
      end

      # Convenience method to add upstream targets
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def add_credential!(details)
        r = if [BasicauthCredential, JWTCredential, KeyauthCredential].include? details.class
              details
            elsif details.is_a?(Hash) && details.key?(:algorithm)
              cred = JWTCredential.new(api_client: api_client)
              cred.algorithm = details[:algorithm]
              cred.key = details[:key] if details[:key]
              cred.secret = details[:secret] if details[:secret]
              cred.rsa_public_key = details[:rsa_public_key] if details[:rsa_public_key]
              cred
            elsif details.is_a?(Hash) && details.key?(:key)
              cred = KeyauthCredential.new(api_client: api_client)
              cred.key = details[:key]
              cred
            elsif details.is_a?(Hash) && details.key?(:username)
              cred = BasicauthCredential.new(api_client: api_client)
              cred.username = details[:username]
              cred.password = details[:password]
              cred
            end

        r.consumer = self
        r.save
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      def credentials
        creds = {}
        keyauth_creds = KeyauthCredential.where(:consumer, self, api_client: api_client)
        creds['key-auth'] = keyauth_creds if keyauth_creds
        basicauth_creds = BasicauthCredential.where(:consumer, self, api_client: api_client)
        creds['basic-auth'] = basicauth_creds if basicauth_creds
        jwt_creds = JWTCredential.where(:consumer, self, api_client: api_client)
        creds['jwt'] = jwt_creds if jwt_creds
        creds
      end

      # Provides a collection of related {Plugin} instances
      def plugins
        Plugin.where(:consumer, self, api_client: api_client)
      end

      def export(options = {})
        hash = { 'username' => username, 'custom_id' => custom_id }
        creds = credentials_for_export
        hash['credentials'] = creds unless creds.empty?
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

        # Find consumers of the same username
        same_username = self.class.where(:username, username)

        existing = same_username.size == 1 ? same_username.first : nil

        if existing
          @entity['id'] = existing.id
          save
        else
          false
        end
      end

      private

      def credentials_for_export
        creds = {}
        unless credentials['key-auth'].empty?
          creds['key-auth'] = credentials['key-auth'].collect do |cred|
            cred.export(exclude: 'consumer')
          end
        end
        unless credentials['jwt'].empty?
          creds['jwt'] = credentials['jwt'].collect do |cred|
            cred.export(exclude: 'consumer')
          end
        end
        unless credentials['basic-auth'].empty?
          creds['basic-auth'] = credentials['basic-auth'].collect do |cred|
            cred.export(exclude: 'consumer')
          end
        end
        creds
      end
    end
  end
end
