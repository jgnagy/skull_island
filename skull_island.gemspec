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
  spec.description   = 'A Ruby SDK for Kong'
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

  spec.required_ruby_version = '~> 3.0'

  spec.add_runtime_dependency 'deepsort', '~> 0.4'
  spec.add_runtime_dependency 'erubi', '~> 1.8'
  spec.add_runtime_dependency 'linguistics', '~> 2.1'
  spec.add_runtime_dependency 'rest-client', '~> 2.1'
  spec.add_runtime_dependency 'thor', '~> 1.0'
  spec.add_runtime_dependency 'will_paginate', '~> 3.1'
  spec.add_runtime_dependency 'yajl-ruby', '~> 1.4'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'coveralls_reborn', '~> 0.20'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.32'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.12'
  spec.add_development_dependency 'simplecov', '~> 0.21'
  spec.add_development_dependency 'simplecov-cobertura', '~> 1.3'
  spec.add_development_dependency 'solargraph', '~> 0.45'
  spec.add_development_dependency 'travis', '~> 1.8'
  spec.add_development_dependency 'yard', '~> 0.9.28'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
