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
    GRPC_HEADERS = %W[x-grpc-web #{GRPC_STATUS_HEADER} #{GRPC_MESSAGE_HEADER}].freeze

    def request(uri, rpc_desc, params = {}, opt_headers = {})
      req_proto = rpc_desc.input.new(params)
      marshalled_proto = rpc_desc.marshal_proc.call(req_proto)
      frame = ::GRPCWeb::MessageFrame.payload_frame(marshalled_proto)
      request_body = ::GRPCWeb::MessageFraming.pack_frames([frame])

      resp = post_request(uri, request_body, opt_headers)
      resp_body = handle_response(resp)
      rpc_desc.unmarshal_proc(:output).call(resp_body)
    end

    private

    def request_headers(opt_headers)
      {
        'Accept' => PROTO_CONTENT_TYPE,
        'Content-Type' => PROTO_CONTENT_TYPE,
      }.merge(opt_headers)
    end

    def post_request(uri, request_body, opt_headers = {})
      request = Net::HTTP::Post.new(uri, request_headers(opt_headers))
      request.body = request_body
      request.basic_auth uri.user, uri.password if uri.userinfo

      begin
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end
      rescue StandardError => e
        raise ::GRPC::Unavailable, e.message
      end
    end

    def handle_response(resp)
      begin
        frames = ::GRPCWeb::MessageFraming.unpack_frames(resp.body)
        headers = extract_headers(frames)
      rescue StandardError
        headers = {}
        error_unpacking_frames = true
      end
      raise_on_response_errors(resp, headers, error_unpacking_frames)

      frames.find(&:payload?).body
    end

    def extract_headers(frames)
      header_frame = frames.find(&:header?)
      if header_frame
        parse_headers(header_frame.body)
      else
        {}
      end
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

    def raise_on_response_errors(resp, headers, error_unpacking_frames)
      metadata = headers.reject { |key, _| GRPC_HEADERS.include?(key) }
      status_str = headers[GRPC_STATUS_HEADER]
      status_code = status_str.to_i if status_str && status_str == status_str.to_i.to_s

      # see https://github.com/grpc/grpc/blob/master/doc/http-grpc-status-mapping.md
      if status_code && status_code != 0
        raise ::GRPC::BadStatus.new_status_exception(
          status_code,
          headers[GRPC_MESSAGE_HEADER],
          metadata,
        )
      end

      case resp
      when Net::HTTPBadRequest # 400
        raise ::GRPC::Internal.new(resp.message, metadata)
      when Net::HTTPUnauthorized # 401
        raise ::GRPC::Unauthenticated.new(resp.message, metadata)
      when Net::HTTPForbidden # 403
        raise ::GRPC::PermissionDenied.new(resp.message, metadata)
      when Net::HTTPNotFound # 404
        raise ::GRPC::Unimplemented.new(resp.message, metadata)
      when Net::HTTPTooManyRequests, # 429
          Net::HTTPBadGateway, # 502
          Net::HTTPServiceUnavailable, # 503
          Net::HTTPGatewayTimeOut # 504
        raise ::GRPC::Unavailable.new(resp.message, metadata)
      else
        raise ::GRPC::Unknown.new(resp.message, metadata) unless resp.is_a?(Net::HTTPSuccess) # 200
        raise ::GRPC::Internal.new(resp.message, metadata) if error_unpacking_frames
        raise ::GRPC::Unknown.new(resp.message, metadata) if status_code.nil?
      end
    end
  end
end
