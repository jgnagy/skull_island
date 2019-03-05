# frozen_string_literal: true

module SkullIsland
  module Helpers
    # Simple helper class methods for Resource
    module ResourceClass
      # Determine a list of names to use to access a resource entity attribute
      # @param original_name [String,Symbol] the name of the underlying attribute
      # @param opts [Hash] property options as defined in a {Resource} subclass
      # @return [Array<Symbol>] the list of names
      def determine_getter_names(original_name, opts)
        names = []
        names << original_name
        names << "#{original_name}?" if opts[:type] == :boolean
        if opts[:as]
          Array(opts[:as]).each do |new_name|
            names << (opts[:type] == :boolean ? "#{new_name}?" : new_name)
          end
        end
        names.map(&:to_sym).uniq
      end

      # Determine a list of names to use to set a resource entity attribute
      # @param original_name [String,Symbol] the name of the underlying attribute
      # @param opts [Hash] property options as defined in a {Resource} subclass
      # @return [Array<Symbol>] the list of names
      def determine_setter_names(original_name, opts)
        names = ["#{original_name}="]
        names.concat(Array(opts[:as]).map { |new_name| "#{new_name}=" }) if opts[:as]
        names.map(&:to_sym).uniq
      end

      # Produce a more human-readable representation of {#i18n_key}
      # @note ActiveRecord ActiveModel::Name compatibility method
      # @return [String]
      def human
        i18n_key.humanize
      end

      # Check if a resource class is immutable
      def immutable?
        @immutable ||= false
      end

      # A mock internationalization key based on the class name
      # @note ActiveRecord ActiveModel::Name compatibility method
      # @return [String]
      def i18n_key
        name.split('::').last.to_underscore
      end

      alias singular_route_key i18n_key

      # A symbolized version of {#i18n_key}
      # @note ActiveRecord ActiveModel::Name compatibility method
      # @return [Symbol]
      def param_key
        i18n_key.to_sym
      end

      # All the properties defined for this Resource class
      # @return [Hash{Symbol => Hash}]
      def properties
        @properties ||= {}
      end

      # A route key for building URLs
      # @note ActiveRecord ActiveModel::Name compatibility method
      # @return [String]
      def route_key
        i18n_key.en.plural
      end
    end
  end
end
