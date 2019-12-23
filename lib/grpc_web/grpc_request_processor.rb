# frozen_string_literal: true

require 'base64'
require 'active_support/core_ext/string'
require 'grpc_web/grpc_web_response'
require 'grpc_web/message_framing'

module GRPCWeb::GRPCRequestProcessor
  GRPC_PROTO_CONTENT_TYPE = 'application/grpc-web+proto'
  GRPC_JSON_CONTENT_TYPE = 'application/grpc-web+json'
  GRPC_TEXT_CONTENT_TYPE = 'application/grpc-web-text'
  GRPC_TEXT_PROTO_CONTENT_TYPE = 'application/grpc-web-text+proto'
  BASE64_CONTENT_TYPES = [GRPC_TEXT_CONTENT_TYPE, GRPC_TEXT_PROTO_CONTENT_TYPE].freeze

  class << self
    def process(grpc_web_request)
      grpc_web_request = decode_request(grpc_web_request)
      grpc_web_request = parse_request(grpc_web_request)
      grpc_web_response = call_service(grpc_web_request)
      grpc_web_response = serialize_response(grpc_web_response)
      encode_response(grpc_web_response)
    end

    private

    def parse_request(request)
      service_class = request.service.class
      request_proto_class = service_class.rpc_descs[request.service_method.to_sym].input
      frames = unframe_request(request.body)
      input_payload = find_payload_frame(frames).body

      if request.content_type == GRPC_JSON_CONTENT_TYPE
        request_proto = request_proto_class.decode_json(input_payload)
      else
        request_proto = request_proto_class.decode(input_payload)
      end

      ::GRPCWeb::GRPCWebRequest.new(
          request.service, request.service_method, request.content_type, request_proto)
    end

    def call_service(request)
      # TODO Validate content_types
      content_type = request.content_type
      content_type = GRPC_PROTO_CONTENT_TYPE if content_type.blank?

      service_method_sym = request.service_method.to_s.underscore
      response = request.service.send(service_method_sym, request.body)

      ::GRPCWeb::GRPCWebResponse.new(content_type, response)
    end

    def decode_request(request)
      return request unless BASE64_CONTENT_TYPES.include?(request.content_type)
      decoded = Base64.decode64(request.body)
      ::GRPCWeb::GRPCWebRequest.new(
          request.service, request.service_method, request.content_type, decoded)
      # TODO Handle multiple base64 encoded frames
    end

    def encode_response(response)
      return response unless BASE64_CONTENT_TYPES.include?(response.content_type)
      encoded = Base64.strict_encode64(response.body)
      ::GRPCWeb::GRPCWebResponse.new(response.content_type, encoded)
      # TODO Handle multiple frames
    end

    def serialize_response(response)
      if response.content_type == GRPC_JSON_CONTENT_TYPE
        payload = response.body.to_json
      else
        payload = response.body.to_proto
      end
      ::GRPCWeb::GRPCWebResponse.new(response.content_type, frame_response(payload))
    end

    # If needed, trailers can be appended to the response as a 2nd
    # base64 encoded string with independent framing.
    def generate_headers(status, message)
      header_str = [
        "grpc-status:#{status}",
        "grpc-message:#{message}",
        'x-grpc-web:1',
        nil # for trailing newline
      ].join("\r\n")
      framed = ::GRPCWeb::MessageFraming.frame_content(header_str, "\x80")
    end

    def unframe_request(content)
      ::GRPCWeb::MessageFraming.unframe_content(content)
    end

    def frame_response(content)
      ::GRPCWeb::MessageFraming.frame_content(content)
    end

    def find_payload_frame(frames)
      ::GRPCWeb::MessageFraming.find_payload_frame(frames)
    end
  end
end
