# frozen_string_literal: true

require 'json'
require 'net/http'

require 'grpc/errors'
require 'grpc_web/content_types'
require 'grpc_web/message_framing'

# Client execution concerns
module GRPCWeb::ClientExecutor
  class << self
    include ::GRPCWeb::ContentTypes

    GRPC_STATUS_HEADER = 'grpc-status'
    GRPC_MESSAGE_HEADER = 'grpc-message'

    def request(uri, rpc_desc, params = {})
      req_proto = rpc_desc.input.new(params)
      marshalled_proto = rpc_desc.marshal_proc.call(req_proto)
      frame = ::GRPCWeb::MessageFrame.payload_frame(marshalled_proto)
      request_body = ::GRPCWeb::MessageFraming.pack_frames([frame])

      resp = post_request(uri, request_body)
      resp_body = handle_response(resp)
      rpc_desc.unmarshal_proc(:output).call(resp_body)
    end

    private

    def request_headers
      {
        'Accept' => PROTO_CONTENT_TYPE,
        'Content-Type' => PROTO_CONTENT_TYPE,
      }
    end

    def post_request(uri, request_body)
      request = Net::HTTP::Post.new(uri, request_headers)
      request.body = request_body
      request.basic_auth uri.user, uri.password if uri.userinfo

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end
    end

    def handle_response(resp)
      unless resp.is_a?(Net::HTTPSuccess)
        raise "Received #{resp.code} #{resp.message} response: #{resp.body}"
      end

      frames = ::GRPCWeb::MessageFraming.unpack_frames(resp.body)
      binding.pry
      header_frame = frames.find(&:header?)
      headers = parse_headers(header_frame.body) if header_frame
      raise_on_error(headers)
      frames.find(&:payload?).body
    end

    def parse_headers(header_str)
      headers = {}
      lines = header_str.split(/\r?\n/)
      lines.each do |line|
        key, value = line.split(':', 2)
        headers[key] = value
      end
      headers
    end

    def raise_on_error(headers)
      return unless headers

      status_str = headers[GRPC_STATUS_HEADER]
      status_code = status_str.to_i if status_str && status_str == status_str.to_i.to_s

      if status_code && status_code != 0
        raise ::GRPC::BadStatus.new_status_exception(status_code, headers[GRPC_MESSAGE_HEADER], headers)
      end
    end
  end
end
