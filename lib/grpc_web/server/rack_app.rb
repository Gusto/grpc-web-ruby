# frozen_string_literal: true

require 'rack/builder'
require 'grpc_web/server/rack_handler'
require 'grpc_web/server/service_class_validator'

# Can be given a service class, an instance of a service class, or a
# service interface class with a block to lazily initialize the service.
#
# Example 1:
#   app.handle(TestHelloService)
#
# Example 2:
#   app.handle(TestHelloService.new)
#
# Example 3:
#   app.handle(HelloService::Service) do
#     require 'test_hello_service'
#     TestHelloService.new
#   end
#
# TODO: in-mem cache the result of lazy initialization
class GRPCWeb::RackApp < ::Rack::Builder
  def handle(service_or_class, &lazy_init_block)
    service_class = service_or_class.is_a?(Class) ? service_or_class : service_or_class.class
    GRPCWeb::ServiceClassValidator.validate(service_class)
    service_config = lazy_init_block || service_or_class

    service_class.rpc_descs.keys.each do |service_method|
      add_service_method_to_app(service_class.service_name, service_config, service_method)
    end
  end

  private

  # Map a path with Rack::Builder corresponding to the service method
  def add_service_method_to_app(service_name, service_config, service_method)
    map("/#{service_name}/#{service_method}") do
      run(RouteHandler.new(service_config, service_method))
    end
  end

  # Handles a single route
  class RouteHandler
    def initialize(service_config, service_method)
      self.service_config = service_config
      self.service_method = service_method
    end

    def call(env)
      GRPCWeb.metrics.time('server.request', tags: ["service_method:#{service_method}"]) do
        ::GRPCWeb::RackHandler.call(service, service_method, env)
      end
    end

    private

    attr_accessor :service_config, :service_method

    def service
      case service_config
      when Proc
        service_config.call
      when Class
        service_config.new
      else
        service_config
      end
    end
  end
end
