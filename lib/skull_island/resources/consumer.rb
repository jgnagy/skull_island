# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Consumer resource class
    #
    # @see https://docs.konghq.com/0.14.x/admin-api/#consumer-object Consumer API definition
    class Consumer < Resource
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
        end
      end

      # Provides a collection of related {Plugin} instances
      def plugins
        Plugin.where(:consumer, self, api_client: api_client)
      end

      def export(options = {})
        hash = { 'username' => username, 'custom_id' => custom_id }
        [*options[:exclude]].each do |exclude|
          hash.delete(exclude.to_s)
        end
        [*options[:include]].each do |inc|
          hash[inc.to_s] = send(:inc)
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
    end
  end
end
