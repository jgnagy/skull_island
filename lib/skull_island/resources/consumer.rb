# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Consumer resource class
    #
    # @see https://docs.konghq.com/0.14.x/admin-api/#consumer-object Consumer API definition
    class Consumer < Resource
      include Helpers::Taggable
      property :username
      property :custom_id
      property :created_at, read_only: true, postprocess: true

      def self.batch_import(data, verbose: false, test: false)
        raise(Exceptions::InvalidArguments) unless data.is_a?(Array)

        data.each_with_index do |resource_data, index|
          resource = new
          resource.username = resource_data['username']
          resource.custom_id = resource_data['custom_id']
          resource.import_update_or_skip(index: index, verbose: verbose, test: test)

          BasicauthCredential.batch_import(
            (
              resource_data.dig('credentials', 'basic-auth') || []
            ).map { |t| t.merge('consumer_id' => resource.id) },
            verbose: verbose,
            test: test
          )

          KeyauthCredential.batch_import(
            (
              resource_data.dig('credentials', 'key-auth') || []
            ).map { |t| t.merge('consumer_id' => resource.id) },
            verbose: verbose,
            test: test
          )
        end
      end

      # Convenience method to add upstream targets
      def add_credential!(details)
        r = if [BasicauthCredential, KeyauthCredential].include? details.class
              details
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

      def credentials
        creds = {}
        keyauth_creds = KeyauthCredential.where(:consumer, self, api_client: api_client)
        creds['key-auth'] = keyauth_creds if keyauth_creds
        basicauth_creds = BasicauthCredential.where(:consumer, self, api_client: api_client)
        creds['basic-auth'] = basicauth_creds if basicauth_creds
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
            cred.export(exclude: 'consumer_id')
          end
        end
        unless credentials['basic-auth'].empty?
          creds['basic-auth'] = credentials['basic-auth'].collect do |cred|
            cred.export(exclude: 'consumer_id')
          end
        end
        creds
      end
    end
  end
end
