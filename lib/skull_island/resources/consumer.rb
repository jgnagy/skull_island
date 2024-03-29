# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Consumer resource class
    #
    # @see https://docs.konghq.com/1.1.x/admin-api/#consumer-object Consumer API definition
    class Consumer < Resource
      include Helpers::Meta

      property :username
      property :custom_id
      property :created_at, read_only: true, postprocess: true
      property :tags, validate: true, preprocess: true, postprocess: true

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def self.batch_import(data, verbose: false, test: false, project: nil, time: nil)
        raise(Exceptions::InvalidArguments) unless data.is_a?(Array)

        known_ids = []

        # rubocop:disable Metrics/BlockLength
        data.each_with_index do |resource_data, index|
          resource = new
          resource.username = resource_data['username']
          resource.custom_id = resource_data['custom_id']
          resource.tags = resource_data['tags'] if resource_data['tags']
          resource.project = project if project
          resource.import_time = (time || Time.now.utc.to_i) if project
          resource.import_update_or_skip(index: index, verbose: verbose, test: test)
          known_ids << resource.id

          known_basic_auths = BasicauthCredential.batch_import(
            (
              resource_data.dig('credentials', 'basic-auth') || []
            ).map { |t| t.merge('consumer' => { 'id' => resource.id }) },
            verbose: verbose,
            test: test
          )

          known_jwt_auths = JWTCredential.batch_import(
            (
              resource_data.dig('credentials', 'jwt') || []
            ).map { |t| t.merge('consumer' => { 'id' => resource.id }) },
            verbose: verbose,
            test: test
          )

          known_key_auths = KeyauthCredential.batch_import(
            (
              resource_data.dig('credentials', 'key-auth') || []
            ).map { |t| t.merge('consumer' => { 'id' => resource.id }) },
            verbose: verbose,
            test: test
          )

          known_acls = AccessControlList.batch_import(
            (
              resource_data['acls'] || []
            ).map { |t| t.merge('consumer' => { 'id' => resource.id }) },
            verbose: verbose,
            test: test
          )

          next unless project

          basic_creds = BasicauthCredential.all.select { |c| c.consumer == resource }
          basic_creds.reject { |res| known_basic_auths.include?(res.id) }.map do |res|
            puts "[WARN] ! Removing #{res.class.name} (#{res.id})"
            res.destroy
          end

          jwt_creds = JWTCredential.all.select { |c| c.consumer == resource }
          jwt_creds.reject { |res| known_jwt_auths.include?(res.id) }.map do |res|
            puts "[WARN] ! Removing #{res.class.name} (#{res.id})"
            res.destroy
          end

          key_creds = KeyauthCredential.all.select { |c| c.consumer == resource }
          key_creds.reject { |res| known_key_auths.include?(res.id) }.map do |res|
            puts "[WARN] ! Removing #{res.class.name} (#{res.id})"
            res.destroy
          end

          acls = AccessControlList.all.select { |acl| acl.consumer == resource }
          acls.reject { |res| known_acls.include?(res.id) }.map do |res|
            puts "[WARN] ! Removing #{res.class.name} (#{res.id})"
            res.destroy
          end
        end
        # rubocop:enable Metrics/BlockLength

        cleanup_except(project, known_ids) if project

        known_ids
      end
      # rubocop:enable Metrics/MethodLength

      def acls
        AccessControlList.where(:consumer, self, api_client: api_client)
      end

      def add_acl!(details)
        r = case details
            when AccessControlList
              details
            when String
              resource = AccessControlList.new(api_client: api_client)
              resource.group = details
              resource
            else
              resource = AccessControlList.new(api_client: api_client)
              resource.group = details[:group]
              resource
            end
        r.consumer = self
        r.save
      end

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

      # rubocop:disable Metrics/AbcSize
      def export(options = {})
        hash = { 'username' => username, 'custom_id' => custom_id }
        creds = credentials_for_export
        hash['credentials'] = creds unless creds.empty?
        hash['acls'] = acls.map { |acl| acl.export(exclude: 'consumer') } unless acls.empty?
        hash['tags'] = tags unless tags.empty?
        [*options[:exclude]].each do |exclude|
          hash.delete(exclude.to_s)
        end
        [*options[:include]].each do |inc|
          hash[inc.to_s] = send(inc.to_sym)
        end
        hash.compact
      end
      # rubocop:enable Metrics/AbcSize

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
