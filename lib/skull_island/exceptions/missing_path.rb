# frozen_string_literal: true

module SkullIsland
  module Exceptions
    # Provided when a method is called on an incomplete resource definition
    class MissingPath < APIException
    end
  end
end
