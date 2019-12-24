# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'base64'
require 'grpc/errors'
require 'grpc_web/content_types'
require 'grpc_web/grpc_web_response'
require 'grpc_web/message_framing'
require 'grpc_web/text_coder'

module GRPCWeb::GRPCRequestProcessor
  class << self
    include ::GRPCWeb::ContentTypes

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

      begin
        response = request.service.send(service_method_sym, request.body)
      rescue => e
        response = e # Return exception as body if one is raised
      end
      ::GRPCWeb::GRPCWebResponse.new(content_type, response)
    end

    def decode_request(request)
      ::GRPCWeb::TextCoder.decode_request(request)
    end

    def encode_response(response)
      ::GRPCWeb::TextCoder.encode_response(response)
    end

    def serialize_response(response)
      if response.body.is_a?(Exception)
        serialize_error_response(response)
      else
        serialize_success_response(response)
      end
    end

    def serialize_success_response(response)
      if response.content_type == GRPC_JSON_CONTENT_TYPE
        payload = response.body.to_json
      else
        payload = response.body.to_proto
      end
      header_str = generate_headers(GRPC::Core::StatusCodes::OK, 'OK')
      body = frame_response(payload) + frame_header(header_str)
      ::GRPCWeb::GRPCWebResponse.new(response.content_type, body)
    end

    def serialize_error_response(response)
      ex = response.body
      if ex.is_a?(::GRPC::BadStatus)
        header_str = generate_headers(ex.code, ex.details)
      else
        header_str = generate_headers(GRPC::BadStatus::UNKNOWN, "#{ex.class.to_s}: #{ex.message}")
      end
      ::GRPCWeb::GRPCWebResponse.new(response.content_type, frame_header(header_str))
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
    end

    def unframe_request(content)
      ::GRPCWeb::MessageFraming.unframe_content(content)
    end

    def frame_response(content)
      ::GRPCWeb::MessageFraming.frame_content(content)
    end

    def frame_header(content)
      ::GRPCWeb::MessageFraming.frame_content(content, "\x80")
    end

    def find_payload_frame(frames)
      ::GRPCWeb::MessageFraming.find_payload_frame(frames)
    end
  end
end
