# frozen_string_literal: true

require 'rack'
require 'rack/cors'
require 'grpc-web'

# Used to build a Rack app hosting the HelloService for integration testing.
module TestGRPCWebApp
  JS_CLIENT_DIR = File.expand_path('../js-client', __dir__)

  def self.build(service_class = TestHelloService)
    grpc_app = GRPCWeb::RackApp.new
    grpc_app.handle(service_class)

    static_app = Rack::Files.new(JS_CLIENT_DIR)

    Rack::Builder.new do
      use Rack::Cors do
        allow do
          origins '*'
          resource '*', headers: :any, methods: %i[get post options]
        end
      end
      use Rack::Lint

      map '/js-client' do
        run static_app
      end

      run grpc_app
    end
  end
end
