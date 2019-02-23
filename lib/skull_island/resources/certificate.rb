# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The Certificate resource class
    #
    # @see https://docs.konghq.com/0.14.x/admin-api/#certificate-object Certificate API definition
    class Certificate < Resource
      property :cert, required: true, validate: true
      property :key, required: true, validate: true
      property :snis, validate: true
      property :created_at, read_only: true, postprocess: true

      private

      # Used to validate {#cert} on set
      def validate_cert(value)
        # only String is allowed
        value.is_a?(String)
      end

      # Used to validate {#key} on set
      def validate_key(value)
        # only String is allowed
        value.is_a?(String)
      end

      # Used to validate {#snis} on set
      def validate_snis(value)
        # only Array is allowed
        value.is_a?(Array)
      end
    end
  end
end
