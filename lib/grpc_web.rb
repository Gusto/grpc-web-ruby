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

    attr_writer :metrics

    attr_reader :metrics
  end
end

GRPCWeb.metrics = GRPCWeb::Metrics::Empty.new
