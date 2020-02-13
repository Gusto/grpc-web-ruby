# frozen_string_literal: true

require 'rack'
require 'rack/cors'
require 'grpc-web'
require 'hello_services_pb'
require 'test_hello_service'

# Used to build a Rack app hosting the HelloService for integration testing.
module TestGRPCWebApp
  def self.build(service_class = TestHelloService)
    GRPCWeb.handle(service_class)

    Rack::Builder.new do
      use Rack::Cors do
        allow do
          origins '*'
          resource '*', headers: :any, methods: %i[post options]
        end
      end
      use Rack::Lint

      run GRPCWeb.rack_app
    end
  end
end
