# frozen_string_literal: true

require 'grpc_web/version'
require 'grpc_web/server/rack_app'
require 'grpc_web/metrics'

module GRPCWeb
  class << self
    def rack_app
      @rack_app ||= ::GRPCWeb::RackApp.new
    end

    def handle(service_or_class, &lazy_init_block)
      rack_app.handle(service_or_class, &lazy_init_block)
    end

    # Instrumentation support
    def dogstatsd=(obj)
      if obj
        GRPCWeb.metrics = GRPCWeb::Metrics::DogStatsD.new(obj)
      else
        GRPCWeb.metrics = GRPCWeb::Metrics::Empty.new
      end
    end

    def metrics=(obj)
      @metrics = obj
    end

    def metrics
      @metrics
    end
  end
end

GRPCWeb.metrics = GRPCWeb::Metrics::Empty.new
