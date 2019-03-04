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

      # Provides a collection of related {Plugin} instances
      def plugins
        Plugin.where(:consumer, self, api_client: api_client)
      end
    end
  end
end
