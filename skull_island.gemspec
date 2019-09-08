# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'skull_island/version'

Gem::Specification.new do |spec|
  spec.name          = 'skull_island'
  spec.version       = SkullIsland::VERSION
  spec.authors       = ['Jonathan Gnagy']
  spec.email         = ['jonathan.gnagy@gmail.com']

  spec.summary       = 'Ruby SDK for Kong'
  spec.description   = 'A Ruby SDK for Kong 0.14.x'
  spec.homepage      = 'https://github.com/jgnagy/skull_island'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.5'

  spec.add_runtime_dependency 'deepsort', '~> 0.4'
  spec.add_runtime_dependency 'erubi', '~> 1.8'
  spec.add_runtime_dependency 'json', '~> 2.1'
  spec.add_runtime_dependency 'linguistics', '~> 2.1'
  spec.add_runtime_dependency 'rest-client', '~> 2.1'
  spec.add_runtime_dependency 'thor', '~> 0.20'
  spec.add_runtime_dependency 'will_paginate', '~> 3.1'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'coveralls', '~> 0.7'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.50'
  spec.add_development_dependency 'simplecov', '~> 0.17'
  spec.add_development_dependency 'travis', '~> 1.8'
  spec.add_development_dependency 'yard', '~> 0.9.20'
end
