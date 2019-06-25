# frozen_string_literal: true

module SkullIsland
  # A generic API resource
  # TODO: Thread safety
  class Resource
    attr_accessor :api_client
    attr_reader :errors, :entity

    include Comparable
    include Validations::Resource
    include Helpers::Resource
    extend Helpers::ResourceClass

    # Can this type of resource be changed client-side?
    def self.immutable(status)
      raise Exceptions::InvalidArguments unless status.is_a?(TrueClass) || status.is_a?(FalseClass)

      @immutable = status
    end

    # Define a property for a model
    # @!macro [attach] property
    #   The $1 property
    # @todo add more validations on options and names
    def self.property(name, options = {})
      @properties ||= {}

      invalid_prop_names = %i[
        > < = class def
        % ! / . ? * {}
        \[\]
      ]

      raise(Exceptions::InvalidProperty) if invalid_prop_names.include?(name.to_sym)

      @properties[name.to_sym] = options
    end

    def self.gen_getter_method(name, opts)
      determine_getter_names(name, opts).each do |method_name|
        define_method(method_name) do
          name_as_string = name.to_s
          reload if @lazy && !@entity.key?(name_as_string)

          if opts[:postprocess]
            send("postprocess_#{name}".to_sym, @entity[name_as_string])
          else
            @entity[name_as_string]
          end
        end
      end
    end

    def self.gen_setter_method(name, opts)
      determine_setter_names(name, opts).each do |method_name|
        define_method(method_name) do |value|
          raise Exceptions::ImmutableModification if immutable?

          if opts[:validate]
            raise Exceptions::InvalidArguments, name unless send("validate_#{name}".to_sym, value)
          end
          @entity[name.to_s] = if opts[:preprocess]
                                 send("preprocess_#{name}".to_sym, value)
                               else
                                 value
                               end
          @tainted = true
          @modified_properties << name.to_sym
        end
      end
    end

    def self.gen_property_methods
      properties.each do |prop, opts|
        # Getter methods
        next if opts[:id_property]

        gen_getter_method(prop, opts) unless opts[:write_only]

        # Setter methods (don't make one for obviously read-only properties)
        gen_setter_method(prop, opts) unless opts[:read_only]
      end
    end

    # The URI (relative to the API base) for this object (or its index/list)
    def self.relative_uri
      route_key
    end

    def self.all(options = {})
      # TODO: Add validations for options
      # TODO: add validation checks for the required pieces

      api_client = options[:api_client] || APIClient.instance

      root = 'data' # root for API JSON response data
      # TODO: do something with lazy requests...

      collection_entity = api_client.cache(relative_uri) do |client|
        client.get(relative_uri)[root]
      end

      ResourceCollection.new(
        collection_entity.collect do |record|
          unless options[:lazy]
            api_client.invalidate_cache_for "#{relative_uri}/#{record['id']}"
            api_client.cache("#{relative_uri}/#{record['id']}") do
              record
            end
          end
          new(
            entity: record,
            lazy: (options[:lazy] ? true : false),
            tainted: false,
            api_client: api_client
          )
        end,
        type: self,
        api_client: api_client
      )
    end

    def self.from_hash(hash)
      # TODO: better options validations
      raise Exceptions::InvalidOptions unless options.is_a?(Hash)

      api_client = options[:api_client] || APIClient.instance

      new(
        entity: hash,
        lazy: true,
        tainted: true,
        api_client: api_client
      )
    end

    # Returns the first (and hopefully only) resource given some criteria
    # This is a very crude helper and could be made much better
    def self.find(attribute, value, options = {})
      results = where(attribute, value, options)
      raise Exceptions::AmbiguousFind, 'Found more than one result' if results.size > 1

      results.first
    end

    def self.get(id, options = {})
      # TODO: Add validations for options

      api_client = options[:api_client] || APIClient.instance

      if options[:lazy]
        new(
          entity: { 'id' => id },
          lazy: true,
          tainted: false,
          api_client: api_client
        )
      else
        entity_data = api_client.cache("#{relative_uri}/#{id}") do |client|
          client.get("#{relative_uri}/#{id}")
        end

        new(
          entity: entity_data,
          lazy: false,
          tainted: false,
          api_client: api_client
        )
      end
    end

    def self.where(attribute, value, options = {})
      # TODO: validate incoming options
      options[:comparison] ||= value.is_a?(Regexp) ? :match : '=='
      api_client = options[:api_client] || APIClient.instance
      all(lazy: (options[:lazy] ? true : false), api_client: api_client).where(
        attribute, value, comparison: options[:comparison]
      )
    end

    def initialize(options = {})
      # TODO: better options validations
      raise Exceptions::InvalidOptions unless options.is_a?(Hash)

      @entity = options[:entity] || {}

      # Allows lazy-loading if we're told this is a lazy instance
      #  This means only the minimal attributes were fetched.
      #  This shouldn't be set by end-users.
      @lazy = options.key?(:lazy) ? options[:lazy] : false
      # This allows local, user-created instances to be differentiated from fetched
      # instances from the backend API. This shouldn't be set by end-users.
      @tainted = options.key?(:tainted) ? options[:tainted] : true
      # This is the API Client used to get data for this resource
      @api_client = options[:api_client] || APIClient.instance
      @errors = {}
      # A place to store which properties have been modified
      @modified_properties = []

      validate_mutability
      validate_id

      self.class.class_eval { gen_property_methods }
    end

    def relative_uri
      "#{self.class.relative_uri}/#{id}"
    end
  end
end
