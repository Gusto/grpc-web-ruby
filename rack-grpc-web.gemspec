# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'grpc_web/version'

Gem::Specification.new do |spec|
  spec.name          = 'grpc-web'
  spec.version       = GRPCWeb::VERSION
  spec.authors       = ['James Shkolnik']
  spec.email         = ['js@gusto.com']

  spec.summary       = 'Mount gRPC services in a Rack or Rails app as gRPC-Web endpoints (over HTTP/1)'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/gusto/grpc-web-ruby'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']

  # spec.add_dependency 'activesupport', '>= 4.0', '< 6.0'
  spec.add_dependency 'grpc', '>= 1.0', '< 2.0'

  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rspec', '~> 3.3'
end
