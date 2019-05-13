# frozen_string_literal: true

module SkullIsland
  module Helpers
    # Simple helper methods for migrating old configs
    module Migration
      def migrate_config(config)
        if config['version'] == '0.14'
          migrate_0_14_to_1_1(config)
        else
          false # Just return false if it can't be migrated
        end
      end

      def migrate_0_14_to_1_1(config)
        new_config = config.dup
        config['plugins']&.each_with_index do |plugin, plugin_index|
          %w[consumer route service].each do |rtype|
            if plugin["#{rtype}_id"]&.start_with?('<%=')
              new_config['plugins'][plugin_index][rtype] = plugin["#{rtype}_id"].dup
              new_config['plugins'][plugin_index].delete("#{rtype}_id")
            elsif plugin["#{rtype}_id"]
              new_config['plugins'][plugin_index][rtype] = {
                'id' => plugin["#{rtype}_id"].dup
              }
            end
          end
        end
        new_config['version'] = '1.1'
        new_config
      end
    end
  end
end
