# frozen_string_literal: true

module SkullIsland
  module Exceptions
    # Resource.find() yielded more than one result...
    class AmbiguousFind < APIException
    end
  end
end
