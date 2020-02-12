# frozen_string_literal: true

require 'grpc_web/version'
require 'grpc_web/server/rack_app'

module GRPCWeb
  class << self
    def rack_app
      @rack_app ||= ::GRPCWeb::RackApp.new
    end

    def handle(service_or_class, &lazy_init_block)
      rack_app.handle(service_or_class, &lazy_init_block)
    end
  end
end
