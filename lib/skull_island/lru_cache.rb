# frozen_string_literal: true

module SkullIsland
  # A very simple Least Recently Used (LRU) cache implementation. Stores data
  # in a Hash, uses a dedicated Array for storing and sorting keys (and
  # implementing the LRU algorithm), and doesn't bother storing access
  # information for cache data. It stores hit and miss counts for the
  # entire cache (not for individual keys). It also uses three mutexes for
  # thread-safety: a write lock, a read lock, and a metadata lock.
  class LRUCache
    attr_reader :max_size, :keys

    # @raise [Exceptions::InvalidCacheSize] if the max_size isn't an Integer
    def initialize(max_size = 10_000)
      raise Exceptions::InvalidCacheSize unless max_size.is_a?(Integer)

      @max_size     = max_size
      @hits         = 0
      @misses       = 0
      @keys         = []
      @data         = {}
      @read_mutex   = Mutex.new
      @write_mutex  = Mutex.new
      @meta_mutex   = Mutex.new
    end

    # Does the cache contain the requested item?
    # This doesn't count against cache misses
    # @param key [Symbol] the index of the potentially cached object
    def has?(key)
      @meta_mutex.synchronize { @keys.include?(key) }
    end

    alias has_key? has?
    alias include? has?

    # The number of items in the cache
    # @return [Fixnum] key count
    def size
      @meta_mutex.synchronize { @keys.size }
    end

    # Convert the contents of the cache to a Hash
    # @return [Hash] the cached data
    def to_hash
      @read_mutex.synchronize { @data.dup }
    end

    # Return a raw Array of the cache data without its keys.
    # Not particularly useful but it may be useful in the future.
    # @return [Array] just the cached values
    def values
      @read_mutex.synchronize { @data.values }
    end

    # Allow iterating over the cached items, represented as key+value pairs
    def each(&block)
      to_hash.each(&block)
    end

    # Invalidate a cached item by its index / key. Returns `nil` if the object
    # doesn't exist.
    # @param key [Symbol] the cached object's index
    def invalidate(key)
      invalidate_key(key)
      @write_mutex.synchronize { @data.delete(key) }
    end

    alias delete invalidate

    # Remove all items from the cache without clearing statistics
    # @return [Boolean] was the truncate operation successful?
    def truncate
      @read_mutex.synchronize do
        @write_mutex.synchronize do
          @meta_mutex.synchronize { @keys = [] }
          @data = {}
        end
        @data.empty?
      end
    end

    # Similar to {#truncate} (in fact, it calls it) but it also clears the
    # statistical metadata.
    # @return [Boolean] was the flush operation successful?
    def flush
      if truncate
        @meta_mutex.synchronize do
          @hits = 0
          @misses = 0
        end
        true
      else
        false
      end
    end

    # Provides a hash of the current metadata for the cache. It provides the
    # current cache size (`:size`),the number of cache hits (`:hits`), and
    # the number of cache misses (`:misses`).
    # @return [Hash] cache statistics
    def statistics
      {
        size: size,
        hits: @meta_mutex.synchronize { @hits },
        misses: @meta_mutex.synchronize { @misses }
      }
    end

    # Store some data (`value`) indexed by a `key`. If an object exists with
    # the same key, and the value is different, it will be overwritten.
    # Storing a value causes its key to be moved to the end of the keys array
    # (meaning it is the __most recently used__ item), and this happens on
    # #store regardless of whether or not the key previously existed.
    # This behavior is relied upon by {#retrieve} to allow reorganization of
    # the keys without necessarily modifying the data it indexes.
    # Uses recursion for overwriting existing items.
    #
    # @param key [Symbol] the index to use for referencing this cached item
    # @param value [Object] the data to cache
    def store(key, value)
      if has?(key)
        if @read_mutex.synchronize { @data[key] == value }
          invalidate_key(key)
          @meta_mutex.synchronize { @keys << key }
          value
        else
          invalidate(key)
          store(key, value)
        end
      else
        invalidate(@keys.first) until size < @max_size

        @write_mutex.synchronize do
          @meta_mutex.synchronize { @keys << key }
          @data[key] = value
        end
      end
    end

    alias []= store

    # Retrieve an item from the cache. Returns `nil` if the item does not
    # exist. Relies on {#store} returning the stored value to ensure the LRU
    # algorithm is maintained safely.
    # @param key [Symbol] the index to retrieve
    def retrieve(key)
      if has?(key)
        @meta_mutex.synchronize { @hits += 1 }
        # Looks dumb, but it actually only reorganizes the keys Array
        store(key, @read_mutex.synchronize { @data[key] })
      else
        @meta_mutex.synchronize { @misses += 1 }
        nil
      end
    end

    alias [] retrieve

    def marshal_dump
      [@max_size, @hits, @misses, @keys, @data]
    end

    def marshal_load(array)
      @max_size, @hits, @misses, @keys, @data = array
    end

    private

    # Invalidate just the key of a cached item. Dangerous if used incorrectly.
    def invalidate_key(key)
      @meta_mutex.synchronize { @keys.delete(key) }
    end
  end
end
