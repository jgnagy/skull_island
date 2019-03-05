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

      def self.batch_import(data, verbose: false)
        raise(Exceptions::InvalidArguments) unless data.is_a?(Array)

        data.each_with_index do |resource_data, index|
          resource = new
          resource.username = resource_data['username']
          resource.custom_id = resource_data['custom_id']
          if resource.find_by_digest
            puts "[INFO] Skipping #{resource.class} index #{index} (#{resource.id})" if verbose
          elsif resource.save
            puts "[INFO] Saved #{resource.class} index #{index} (#{resource.id})" if verbose
          else
            puts "[ERR] Failed to save #{resource.class} index #{index}"
          end
        end
      end

      # Provides a collection of related {Plugin} instances
      def plugins
        Plugin.where(:consumer, self, api_client: api_client)
      end

      def to_hash(options = {})
        hash = { 'username' => username, 'custom_id' => custom_id }
        [*options[:exclude]].each do |exclude|
          hash.delete(exclude.to_s)
        end
        [*options[:include]].each do |inc|
          hash[inc.to_s] = send(:inc)
        end
        hash.reject { |_, value| value.nil? }
      end
    end
  end
end
