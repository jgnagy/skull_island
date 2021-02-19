# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'
require 'simplecov-json'
require 'coveralls'

# Generate HTML and JSON reports
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ]
)

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/.bundle/'
end

Coveralls.wear!

require 'skull_island'
require 'skull_island/rspec'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  include SkullIsland::RSpec
end
