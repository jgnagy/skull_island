# frozen_string_literal: true

module SkullIsland
  # The ResourceCollection class
  # Should not allow or use mixed types
  class ResourceCollection
    include Enumerable
    include Comparable

    # @return [Class] a collection of this {Resource} subclass
    attr_reader :type

    def initialize(list, options = {})
      # TODO: better options validations
      raise Exceptions::InvalidOptions unless options.is_a?(Hash)
      raise Exceptions::InvalidArguments if list.empty? && options[:type].nil?

      @api_client = options[:api_client] || APIClient.instance
      @list = list
      @type = options[:type] || list.first.class
    end

    def each(&block)
      @list.each(&block)
    end

    # Does the collection contain anything?
    # @return [Boolean]
    def empty?
      @list.empty?
    end

    # Provide the first (or first `number`) entries
    # @param number [Fixnum] How many to provide
    # @return [ResourceCollection,Resource]
    def first(number = nil)
      if number
        self.class.new(@list.first(number), type: @type, api_client: @api_client)
      else
        @list.first
      end
    end

    # Provide the last (or last `number`) entries
    # @param number [Fixnum] How many to provide
    # @return [ResourceCollection,Resource]
    def last(number = nil)
      if number
        self.class.new(@list.last(number), type: @type, api_client: @api_client)
      else
        @list.last
      end
    end

    # Merge two collections
    # @param other [ResourceCollection]
    # @return [ResourceCollection]
    def merge(other)
      raise Exceptions::InvalidArguments unless other.is_a?(self.class)

      self + (other - self)
    end

    # An alias for {#type}
    def model
      type
    end

    # Hacked together #or() method in the same spirit as #where().
    # This method can be chained for multiple / more specific queries.
    #
    # @param attribute [Symbol] the attribute to query
    # @param value [Object] the value to compare against
    #   - allowed options are "'==', '!=', '>', '>=', '<', '<=', and 'match'"
    # @raise [Exceptions::InvalidWhereQuery] if not the right kind of comparison
    # @return [ResourceCollection]
    def or(attribute, value, options = {})
      options[:comparison] ||= value.is_a?(Regexp) ? :match : '=='
      if empty?
        @type.where(attribute, value, comparison: options[:comparison], api_client: @api_client)
      else
        merge first.class.where(
          attribute, value,
          comparison: options[:comparison],
          api_client: @api_client
        )
      end
    end

    # Pass pagination through to the Array (which passes to will_paginate)
    def paginate(*args)
      @list.paginate(*args)
    end

    # Returns the number of Resource instances in the collection
    # @return [Fixnum]
    def size
      @list.size
    end

    # Allow complex sorting like an Array
    # @return [ResourceCollection] sorted collection
    def sort(&block)
      self.class.new(super(&block), type: @type, api_client: @api_client)
    end

    # Horribly inefficient way to allow querying Resources by their attributes.
    # This method can be chained for multiple / more specific queries.
    #
    # @param attribute [Symbol] the attribute to query
    # @param value [Object] the value to compare against
    #   - allowed options are "'==', '!=', '>', '>=', '<', '<=', and 'match'"
    # @raise [Exceptions::InvalidWhereQuery] if not the right kind of comparison
    # @return [ResourceCollection]
    def where(attribute, value, options = {})
      valid_comparisons = %i[== != > >= < <= match]
      options[:comparison] ||= value.is_a?(Regexp) ? :match : '=='
      unless valid_comparisons.include?(options[:comparison].to_sym)
        raise Exceptions::InvalidWhereQuery
      end

      self.class.new(
        @list.collect do |item|
          if item.send(attribute).nil?
            nil
          elsif item.send(attribute).send(options[:comparison].to_sym, value)
            item
          end
        end.compact,
        type: @type,
        api_client: @api_client
      )
    end

    alias and where

    # Return the collection item at the specified index
    # @return [Resource,ResourceCollection] the item at the requested index
    def [](index)
      if index.is_a?(Range)
        self.class.new(@list[index], type: @type, api_client: @api_client)
      else
        @list[index]
      end
    end

    # Return a collection after subtracting from the original
    # @return [ResourceCollection]
    def -(other)
      if other.respond_to?(:to_a)
        self.class.new(@list - other.to_a, type: @type, api_client: @api_client)
      elsif other.is_a?(Resource)
        self.class.new(@list - Array(other), type: @type, api_client: @api_client)
      else
        raise Exceptions::InvalidArguments
      end
    end

    # Return a collection after adding to the original
    #   Warning: this may cause duplicates or mixed type joins! For safety,
    #   use #merge
    # @return [ResourceCollection]
    def +(other)
      case other
      when self.class
        self.class.new(@list + other.to_a, type: @type, api_client: @api_client)
      when @type
        self.class.new(@list + [other], type: @type, api_client: @api_client)
      else
        raise Exceptions::InvalidArguments
      end
    end

    def <<(other)
      raise Exceptions::InvalidArguments, 'Resource Type Mismatch' unless other.instance_of?(@type)

      @list << other
    end

    def <=>(other)
      collect(&:id).sort <=> other.collect(&:id).sort
    end

    # Allow comparison of collection
    # @return [Boolean] do the collections contain the same resource ids?
    def ==(other)
      if other.is_a? self.class
        collect(&:id).sort == other.collect(&:id).sort
      else
        false
      end
    end
  end
end
