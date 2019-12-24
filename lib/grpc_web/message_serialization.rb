# frozen_string_literal: true

require 'grpc/core/status_codes'
require 'grpc/errors'
require 'grpc_web/content_types'
require 'grpc_web/grpc_web_response'
require 'grpc_web/grpc_web_request'
require 'grpc_web/message_framing'

module GRPCWeb::MessageSerialization
  class << self
    include ::GRPCWeb::ContentTypes

    def deserialize_request(request)
      service_class = request.service.class
      request_proto_class = service_class.rpc_descs[request.service_method.to_sym].input
      frames = framing.unframe_content(request.body)
      input_payload = frames.find(&:payload?).body

      if request.content_type == GRPC_JSON_CONTENT_TYPE
        request_proto = request_proto_class.decode_json(input_payload)
      else
        request_proto = request_proto_class.decode(input_payload)
      end

      ::GRPCWeb::GRPCWebRequest.new(
          request.service, request.service_method, request.content_type, request_proto)
    end

    def serialize_response(response)
      if response.body.is_a?(Exception)
        serialize_error_response(response)
      else
        serialize_success_response(response)
      end
    end

    private

    def serialize_success_response(response)
      if response.content_type == GRPC_JSON_CONTENT_TYPE
        payload = response.body.to_json
      else
        payload = response.body.to_proto
      end
      header_str = generate_headers(::GRPC::Core::StatusCodes::OK, 'OK')
      body = framing.frame_content(payload) + framing.frame_header(header_str)
      ::GRPCWeb::GRPCWebResponse.new(response.content_type, body)
    end

    def serialize_error_response(response)
      ex = response.body
      if ex.is_a?(::GRPC::BadStatus)
        header_str = generate_headers(ex.code, ex.details)
      else
        header_str = generate_headers(::GRPC::Core::StatusCodes::UNKNOWN, "#{ex.class.to_s}: #{ex.message}")
      end
      ::GRPCWeb::GRPCWebResponse.new(response.content_type, framing.frame_header(header_str))
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

    def framing
      ::GRPCWeb::MessageFraming
    end
  end
end
