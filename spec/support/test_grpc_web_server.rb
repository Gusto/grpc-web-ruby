# frozen_string_literal: true

pb_path = File.expand_path('../pb-ruby', __dir__)
lib = File.expand_path('../../lib', __dir__)
$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)
$LOAD_PATH.unshift(pb_path) unless $LOAD_PATH.include?(pb_path)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rack'
require 'rack/cors'
require 'grpc-web'
require 'test_hello_service'

grpc_app = GRPCWeb::RackApp.for_services([
  proc { TestHelloService.new },
])

app = Rack::Builder.new do
  use Rack::Cors do
    allow do
       origins '*'
       resource '*', :headers => :any, :methods => [:post, :options]
     end
  end

  run grpc_app
end

Rack::Handler::WEBrick.run app
