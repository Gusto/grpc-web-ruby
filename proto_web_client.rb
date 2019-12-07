#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'json'
# require 'bundler/setup'
require 'active_support/core_ext/string'

pb_path = File.expand_path('spec/pb-ruby', __dir__)
$LOAD_PATH.unshift(pb_path) unless $LOAD_PATH.include?(pb_path)

require 'hello_services_pb'


class GrpcWebClient
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
    req.body = frame_request(req_proto.to_proto)

    resp_proto = nil
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      resp = http.request(req)
      unframed_response = resp.body[5..-1]
      resp_proto = rpc_desc.output.decode(unframed_response)
    end

    resp_proto
  end

  # GRPC-Web uses a simple 5 byte framing scheme. The first byte represents
  # flags indicating what type of frame this is. The next 4 bytes indicate the
  # byte length of the frame body.
  def frame_request(response, flags = "\x00")
    length_bytes = [response.bytesize].pack('N')
    "#{flags}#{length_bytes}#{response}"
  end
end

client = GrpcWebClient.new('http://localhost:8080', HelloService)
puts client.say_hello(name: 'James')

# curl -d '{"id":"1"}' -H "Content-Type: application/grpc-web+json" -X POST http://localhost:3500/rpc/schemas/monolith/CompanyService/GetCompany
