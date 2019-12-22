# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'json'
require 'net/http'
require 'uri'
require 'grpc_web/message_framing'

module GRPCWeb
  class Client
    GRPC_PROTO_CONTENT_TYPE = 'application/grpc-web+proto'
    SERVICE_CONST = 'Service'

    attr_accessor :base_url, :service_interface

    def initialize(base_url, service_interface)
      self.base_url = base_url
      self.service_interface = service_interface
    end

    def method_missing(method, params = {})
      rpc_name = method.to_s.camelize
      perform_request(rpc_name, params)
    end

    private

    def perform_request(service_method, params = {})
      service_class = service_interface.const_get(SERVICE_CONST)
      rpc_desc = service_class.rpc_descs[service_method.to_sym]
      req_proto = rpc_desc.input.new(params)

      uri = URI(File.join(base_url, service_class.service_name, service_method))
      req = Net::HTTP::Post.new(uri, 'Accept' => GRPC_PROTO_CONTENT_TYPE, 'Content-Type' => GRPC_PROTO_CONTENT_TYPE)
      req.body = ::GRPCWeb::MessageFraming.frame_content(req_proto.to_proto)

      resp_proto = nil
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        resp = http.request(req)
        unframed_response = ::GRPCWeb::MessageFraming.unframe_content(resp.body)
        resp_proto = rpc_desc.output.decode(unframed_response)
      end

      resp_proto
    end
  end
end
