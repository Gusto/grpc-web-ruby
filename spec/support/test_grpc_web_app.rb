# frozen_string_literal: true

require 'rack'
require 'rack/cors'
require 'grpc-web'
require 'test_hello_service'

# Used to build a Rack app hosting the HelloService for integration testing.
module TestGRPCWebApp
  def self.build(service_class = TestHelloService)
    grpc_app = GRPCWeb::RackApp.for_services([
      proc { service_class.new },
    ])

    Rack::Builder.new do
      use Rack::Cors do
        allow do
           origins '*'
           resource '*', :headers => :any, :methods => [:post, :options]
         end
      end

      run grpc_app
    end
  end
end
