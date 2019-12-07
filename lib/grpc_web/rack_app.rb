# frozen_string_literal: true

require 'rack/builder'
require 'grpc_web/rack_handler'

module GRPCWeb
  module RackApp
    class << self
      def for_services(services)
        builder = Rack::Builder.new
        # builder.use Rack::Cors do
        #   allow do
        #      origins '*'
        #      resource '*', :headers => :any, :methods => [:post, :options]
        #    end
        # end
        services.each do |service_or_proc|
          add_service_to_app(builder, service_or_proc)
        end
        builder
      end

      def call_if_proc(service_or_proc)
        if service_or_proc.is_a?(Proc)
          service_or_proc.call
        else
          service_or_proc
        end
      end

      private

      def add_service_to_app(builder, service_or_proc)
        service_class = call_if_proc(service_or_proc).class
        base_path = service_class.service_name

        service_class.rpc_descs.keys.each do |service_method|
          builder.map "/#{base_path}/#{service_method}" do
            run ->(env) do
              service = ::GRPCWeb::RackApp.call_if_proc(service_or_proc)
              ::GRPCWeb::RackHandler.call(service, service_method, env)
            end
          end
        end
      end

    end
  end
end
