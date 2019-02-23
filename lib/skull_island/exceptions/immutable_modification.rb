# frozen_string_literal: true

module SkullIsland
  module Exceptions
    # Provided when an attempt is made to modify an immutable resource
    class ImmutableModification < APIException
    end
  end
end
