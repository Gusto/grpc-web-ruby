# frozen_string_literal: true

require 'uri'
require 'grpc_web/client_executor'

module GRPCWeb
  class Client

    attr_reader :base_url, :service_interface

    def initialize(base_url, service_interface)
      self.base_url = base_url
      self.service_interface = service_interface

      service_interface.rpc_descs.each do |rpc_method, rpc_desc|
        define_rpc_method(rpc_method, rpc_desc)
      end
    end

    private

    attr_writer :base_url, :service_interface

    def define_rpc_method(rpc_method, rpc_desc)
      ruby_method = ::GRPC::GenericService.underscore(rpc_method.to_s).to_sym
      define_singleton_method(ruby_method) do |params = {}|
        uri = endpoint_uri(rpc_desc)
        ::GRPCWeb::ClientExecutor.request(uri, rpc_desc, params)
      end
    end

    def endpoint_uri(rpc_desc)
      URI(File.join(base_url, service_interface.service_name, rpc_desc.name.to_s))
    end

  end
end
