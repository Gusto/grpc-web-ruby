# frozen_string_literal: true

require 'uri'
require 'grpc_web/client/client_executor'

# GRPC Client implementation
# Example usage:
#
# client = GRPCWeb::Client.new("http://localhost:3000/grpc", HelloService::Service)
# client.username = "foo"
# client.password = "password"
# client.say_hello(name: 'James')
class GRPCWeb::Client
  attr_reader :base_url, :service_interface
  attr_accessor :username, :password

  def initialize(base_url, service_interface)
    uri = URI(base_url)

    if uri.user_info
      self.username = uri.user
      self.password = uri.password

      uri.password = nil
      uri.user = nil
    end

    self.base_url = uri.to_s
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
      ::GRPCWeb::ClientExecutor.request(uri, rpc_desc, username, password, params)
    end
  end

  def endpoint_uri(rpc_desc)
    URI(File.join(base_url, service_interface.service_name, rpc_desc.name.to_s))
  end
end
