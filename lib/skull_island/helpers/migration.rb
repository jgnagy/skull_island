# frozen_string_literal: true

module SkullIsland
  module Helpers
    # Simple helper methods for migrating old configs
    module Migration
      def migrate_config(config)
        if config['version'] == '0.14'
          migrate_config migrate_0_14_to_1_1(config)
        elsif ['1.0', '1.1', '1.2', '1.3'].include?(config['version'])
          migrate_config migrate_1_1_to_1_4(config)
        elsif config['version'] == '1.4'
          migrate_config migrate_1_4_to_1_5(config)
        elsif config['version'] == '1.5'
          migrate_1_5_to_2_0(config)
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

      def migrate_1_1_to_1_4(config)
        new_config = config.dup
        new_config['version'] = '1.4'
        new_config
      end

      def migrate_1_4_to_1_5(config)
        new_config = config.dup
        new_config['version'] = '1.5'
        new_config
      end

      def migrate_1_5_to_2_0(config)
        new_config = config.dup
        new_config['version'] = '2.0'
        new_config
      end
    end
  end
end
