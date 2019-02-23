# frozen_string_literal: true

module SkullIsland
  module Validations
    # Resource validation methods
    module Resource
      def validate_mutability
        raise Exceptions::ImmutableModification if immutable? && @tainted # this shouldn't happen
      end

      # The 'id' field should not be set manually
      def validate_id
        raise Exceptions::NewInstanceWithID if @entity.key?('id') && @tainted
      end

      # Ensure that required properties are set before saving
      def validate_required_properties(data)
        required_properties.each do |name, _value|
          raise Exceptions::InvalidArguments if data[name.to_s].nil?
        end
      end
    end
  end
end
