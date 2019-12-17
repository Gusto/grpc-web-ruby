# frozen_string_literal: true

require 'rack'
require 'rack/cors'
require 'grpc-web'
require 'test_hello_service'

module TestGRPCWebApp
  def self.build
    grpc_app = GRPCWeb::RackApp.for_services([
      proc { TestHelloService.new },
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
