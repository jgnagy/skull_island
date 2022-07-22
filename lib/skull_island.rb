# frozen_string_literal: true

# Core Extensions
require 'core_extensions/string/transformations'
require 'core_extensions/hash/pruning'

# Including extensions to the String core class
class String
  include CoreExtensions::String::Transformations
end

# Including extensions to the Hash core class
class Hash
  include CoreExtensions::Hash::Pruning
end

# Standard Library Requirements
require 'date'
require 'digest'
require 'singleton'
require 'uri'
require 'yaml'

# External Library Requirements
require 'deepsort'
require 'erubi'
require 'linguistics'
Linguistics.use(:en)
require 'rest-client'
require 'will_paginate'
require 'will_paginate/array'
require 'yajl/json_gem'

# Internal Requirements
require 'skull_island/version'
require 'skull_island/api_exception'
require 'skull_island/exceptions/ambiguous_find'
require 'skull_island/exceptions/api_client_not_configured'
require 'skull_island/exceptions/immutable_modification'
require 'skull_island/exceptions/invalid_arguments'
require 'skull_island/exceptions/invalid_cache_size'
require 'skull_island/exceptions/invalid_options'
require 'skull_island/exceptions/invalid_property'
require 'skull_island/exceptions/invalid_where_query'
require 'skull_island/exceptions/new_instance_with_id'
require 'skull_island/helpers/api_client'
require 'skull_island/validations/api_client'
require 'skull_island/lru_cache'
require 'skull_island/api_client_base'
require 'skull_island/api_client'
require 'skull_island/simple_api_client'
require 'skull_island/resource_collection'
require 'skull_island/helpers/cli_erb'
require 'skull_island/helpers/meta'
require 'skull_island/helpers/resource'
require 'skull_island/helpers/resource_class'
require 'skull_island/helpers/migration'
require 'skull_island/validations/resource'
require 'skull_island/resource'
require 'skull_island/resources/access_control_list'
require 'skull_island/resources/ca_certificate'
require 'skull_island/resources/certificate'
require 'skull_island/resources/basicauth_credential'
require 'skull_island/resources/jwt_credential'
require 'skull_island/resources/keyauth_credential'
require 'skull_island/resources/consumer'
require 'skull_island/resources/plugin'
require 'skull_island/resources/service'
require 'skull_island/resources/route'
require 'skull_island/resources/upstream'
require 'skull_island/resources/upstream_target'

module SkullIsland
  class Error < StandardError; end
  # Your code goes here...
end
