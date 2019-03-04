# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Upstream resource class
    #
    # @see https://docs.konghq.com/0.14.x/admin-api/#upstream-objects Upstream API definition
    class Upstream < Resource
      property :name, required: true, validate: true
      property :slots, validate: true
      property :hash_on, validate: true
      property :hash_fallback, validate: true
      property :hash_on_header, validate: true
      property :hash_fallback_header, validate: true
      property :hash_on_cookie, validate: true
      property :hash_on_cookie_path, validate: true
      property :healthchecks, validate: true
      property :created_at, read_only: true, postprocess: true

      def health
        if new?
          # No health status for new Upstreams
          nil
        else
          health_json = api_client.get("#{relative_uri}/health")
          health_json['data']
        end
      end

      # Convenience method to add upstream targets
      def add_target!(details)
        r = if details.is_a?(UpstreamTarget)
              details
            else
              UpstreamTarget.from_hash(details, api_client: api_client)
            end

        r.upstream = self
        r.save
      end

      def target(target_id)
        UpstreamTarget.new(
          entity: { 'id' => target_id, 'upstream_id' => id },
          lazy: true,
          tainted: false,
          api_client: api_client
        )
      end

      def targets
        target_list_data = api_client.get("#{relative_uri}/targets")
        root = 'data' # root for API JSON response data
        # TODO: do something with lazy requests...

        ResourceCollection.new(
          target_list_data[root].each do |record|
            UpstreamTarget.new(
              entity: record,
              lazy: false,
              tainted: false,
              api_client: api_client
            )
          end,
          type: UpstreamTarget,
          api_client: api_client
        )
      end

      private

      # Used to validate {#hash_on} on set
      def validate_hash_on(value)
        # only String of an acceptable value are allowed
        %w[none consumer ip header cookie].include?(value)
      end

      # Used to validate {#hash_fallback} on set
      def validate_hash_fallback(value)
        # only String of an acceptable value are allowed
        %w[none consumer ip header cookie].include?(value)
      end

      # Used to validate {#hash_on_header} on set
      def validate_hash_on_header(value)
        # only String is allowed and only when {#hash_on} is set to 'header'
        value.is_a?(String) && hash_on == 'header'
      end

      # Used to validate {#hash_fallback_header} on set
      def validate_hash_fallback_header(value)
        # only String is allowed and only when {#hash_fallback} is set to 'header'
        value.is_a?(String) && hash_fallback == 'header'
      end

      # Used to validate {#hash_on_cookie} on set
      def validate_hash_on_cookie(value)
        # only String is allowed and only when {#hash_on} or {#hash_fallback} is set to 'cookie'
        value.is_a?(String) && [hash_on, hash_fallback].include?('cookie')
      end

      # Used to validate {#hash_cookie_path} on set
      def validate_hash_cookie_path(value)
        # only String is allowed and only when {#hash_on} or {#hash_fallback} is set to 'cookie'
        value.is_a?(String) && [hash_on, hash_fallback].include?('cookie')
      end

      # Used to validate {#name} on set
      def validate_name(value)
        # only String is allowed
        value.is_a?(String)
      end

      # Used to validate {#slots} on set
      def validate_slots(value)
        # only Integer is allowed
        value.is_a?(Integer)
      end

      # Used to validate {#healthchecks} on set
      def validate_healthchecks(value)
        # TODO: seriously need to make this better...
        # only Hash is allowed
        value.is_a?(Hash)
      end
    end
  end
end
