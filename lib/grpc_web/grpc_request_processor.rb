# frozen_string_literal: true

require 'base64'
require 'active_support/core_ext/string'
require 'grpc_web/grpc_web_response'

module GRPCWeb::GRPCRequestProcessor
  GRPC_PROTO_CONTENT_TYPE = 'application/grpc-web+proto'
  GRPC_JSON_CONTENT_TYPE = 'application/grpc-web+json'
  GRPC_TEXT_CONTENT_TYPE = 'application/grpc-web-text'
  GRPC_TEXT_PROTO_CONTENT_TYPE = 'application/grpc-web-text+proto'

  class << self
    def process(grpc_web_request)
      service = grpc_web_request.service
      service_class = service.class
      service_method = grpc_web_request.service_method

      request_proto_class = service_class.rpc_descs[service_method.to_sym].input
      request_content_type = grpc_web_request.content_type
      request_body = grpc_web_request.body

      request_proto = parse_request(request_proto_class, request_content_type, request_body)
      response_proto = call_service(service, service_method, request_proto)
      generate_response(response_proto, request_content_type)
    end

    private

    def parse_request(proto_class, content_type, body)
      content_type = GRPC_PROTO_CONTENT_TYPE if content_type.blank?

      if content_type == GRPC_TEXT_CONTENT_TYPE || content_type == GRPC_TEXT_PROTO_CONTENT_TYPE
        body = Base64.decode64(body)
      end

      message = unframe_request(body)

      if content_type == GRPC_JSON_CONTENT_TYPE
        proto_class.decode_json(message)
      else
        proto_class.decode(message)
      end
    end

    def call_service(service, service_method, request_proto)
      service.send(service_method.to_s.underscore, request_proto)
    end

    def generate_response(response_proto, content_type)
      content_type = GRPC_PROTO_CONTENT_TYPE if content_type.blank?

      if content_type == GRPC_JSON_CONTENT_TYPE
        ::GRPCWeb::GRPCWebResponse.new(GRPC_JSON_CONTENT_TYPE, frame_response(response_proto.to_json))
      elsif [GRPC_TEXT_CONTENT_TYPE, GRPC_TEXT_PROTO_CONTENT_TYPE].include?(content_type)
        response = frame_response(response_proto.to_proto)
        ::GRPCWeb::GRPCWebResponse.new(GRPC_TEXT_PROTO_CONTENT_TYPE, Base64.strict_encode64(response))
      else
        ::GRPCWeb::GRPCWebResponse.new(GRPC_PROTO_CONTENT_TYPE, frame_response(response_proto.to_proto))
      end
    end

    # GRPC Web uses a simple 5 byte framing scheme. The first byte represents
    # flags indicating what type of frame this is. The next 4 bytes indicate the
    # byte length of the frame body.
    def frame_response(response, flags = "\x00")
      length_bytes = [response.bytesize].pack('N')
      "#{flags}#{length_bytes}#{response}"
    end

    def unframe_request(body)
      raise "Invalid request format" if body[0] != "\x00"

      msg_length = body[1..4].unpack("N").first
      raise "Invalid message length" if msg_length <= 0

      body[5..(5 + msg_length)]
    end

    # If needed, trailers can be appended to the response as a 2nd
    # base64 encoded string with independent framing.
    def generate_trailers
      frame_response([
        'grpc-status:0',
        'grpc-message:OK',
        'x-grpc-web:1',
      ].join("\r\n"), "\x80")
    end
  end
end
