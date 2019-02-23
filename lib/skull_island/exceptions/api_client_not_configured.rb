# frozen_string_literal: true

module SkullIsland
  module Exceptions
    # The client must be configured before it can be used
    class APIClientNotConfigured < APIException
    end
  end
end
