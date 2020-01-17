# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'grpc_web/version'

Gem::Specification.new do |spec|
  spec.name          = 'grpc-web'
  spec.version       = GRPCWeb::VERSION
  spec.authors       = ['James Shkolnik']
  spec.email         = ['js@gusto.com']

  spec.summary       = 'Host gRPC-Web endpoints for Ruby gRPC services in a Rack or Rails app (over HTTP/1.1). Client included.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/gusto/grpc-web-ruby'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency 'grpc', '~> 1.0'
  spec.add_dependency 'rack', '>= 1.6.0', '< 3.0'

  spec.add_development_dependency 'apparition'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rack-cors'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.3'
  spec.add_development_dependency 'rubocop', '~> 0.79.0'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'simplecov'
end
