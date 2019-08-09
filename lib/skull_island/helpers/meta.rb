# frozen_string_literal: true

module SkullIsland
  module Helpers
    # Useful for embedding meta-data into special tags
    module Meta
      def add_meta(key, value)
        metatag = "_meta~#{key}~#{value}"

        # filter out any existing duplicate metatags
        existing_tags = raw_tags.reject { |tag| tag.start_with?("_meta~#{key}~") }

        # Add the new tag directly, bypassing preprocessing
        raw_set('tags', existing_tags + [metatag])
      end

      def import_time
        metatags['import_time']
      end

      def import_time=(time)
        add_meta('import_time', time)
      end

      def remove_meta(key)
        # filter out an existing metatags
        filtered_tags = raw_tags.reject { |tag| tag.start_with?("_meta~#{key}~") }

        # Bypassing preprocessing
        raw_set('tags', filtered_tags)
      end

      def metatags
        metadata = {}
        raw_tags.select { |tag| tag.start_with?('_meta~') }.each do |tag|
          key, value = tag.gsub('_meta~', '').split('~', 2)
          metadata[key] = value
        end
        metadata
      end

      def project
        metatags['project']
      end

      def project=(project_id)
        unless project_id.is_a?(String) && project_id.match?(/^[\w_\-\.~]+$/)
          raise Exceptions::InvalidArguments, 'project'
        end

        add_meta('project', project_id)
      end

      def raw_tags
        reload if @lazy && !@entity.key?('tags')
        @entity['tags'] || []
      end

      def preprocess_tags(input)
        input.uniq + metatags.map { |k, v| "_meta~#{k}~#{v}" }
      end

      def postprocess_tags(value)
        (value || []).reject { |tag| tag.start_with?('_meta~') }
      end

      def supports_meta?
        true
      end
    end
  end
end
