# frozen_string_literal: true

module SkullIsland
  # A generic API resource
  # TODO: Thread safety
  class Resource
    attr_accessor :client
    attr_reader :errors

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

    # Set the URI path for a resource method
    # @param kind [Symbol] how to refer to the URI
    # @param uri [String] an API URI to refer to later
    def self.path(kind, uri)
      paths[kind.to_sym] = uri
    end

    # Create or set a class-level location to store URI paths for methods
    # @return [Hash{Symbol => String}]
    def self.paths
      @paths ||= {}
    end

    def self.path_for(kind)
      guess = kind.to_sym == :all ? route_key : "#{route_key}/#{kind}"
      paths[kind.to_sym] || guess
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
            raise Exceptions::InvalidArguments unless send("validate_#{name}".to_sym, value)
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

    def self.all(options = {})
      # TODO: Add validations for options

      # TODO: add validation checks for the required pieces
      raise Exceptions::MissingPath unless path_for(:all)

      api_client = options[:api_client] || APIClient.instance

      root = 'data' # root for API JSON response data
      # TODO: do something with lazy requests...

      ResourceCollection.new(
        api_client.get(path_for(:all))[root].collect do |record|
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
      raise Exceptions::MissingPath unless path_for(:all)

      api_client = options[:api_client] || APIClient.instance

      new(
        entity: hash,
        lazy: true,
        tainted: true,
        api_client: api_client
      )
    end

    def self.get(id, options = {})
      # TODO: Add validations for options
      raise Exceptions::MissingPath unless path_for(:all)

      api_client = options[:api_client] || APIClient.instance

      new(
        entity: api_client.get("#{path_for(:all)}/#{id}"),
        lazy: false,
        tainted: false,
        api_client: api_client
      )
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

    def destroy
      raise Exceptions::ImmutableModification if immutable?

      unless new?
        @api_client.delete("#{path_for(:all)}/#{id}")
        @lazy = false
        @tainted = true
        @entity.delete('id')
      end
      true
    end

    def reload
      if new?
        # Can't reload a new resource
        false
      else
        @entity  = @api_client.get("#{path_for(:all)}/#{id}")
        @lazy    = false
        @tainted = false
        true
      end
    end

    def save
      saveable_data = @entity.select do |prop, value|
        pr = prop.to_sym
        go = properties.key?(pr) && !properties[pr][:read_only] && !value.nil?
        @modified_properties.uniq.include?(pr) if go
      end

      validate_required_properties(saveable_data)

      if new?
        @entity  = @api_client.post(path_for(:all).to_s, saveable_data)
        @lazy    = true
      else
        @api_client.put("#{path_for(:all)}/#{id}", saveable_data)
      end
      @tainted = false
      true
    end
  end
end
