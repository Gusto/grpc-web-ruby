# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'grpc_web/content_types'
require 'grpc_web/grpc_web_response'
require 'grpc_web/message_framing'
require 'grpc_web/message_serialization'
require 'grpc_web/text_coder'

module GRPCWeb::GRPCRequestProcessor
  class << self
    include ::GRPCWeb::ContentTypes

    def process(grpc_web_request)
      text_coder = ::GRPCWeb::TextCoder
      framing = ::GRPCWeb::MessageFraming
      serialization = ::GRPCWeb::MessageSerialization

      grpc_web_request = text_coder.decode_request(grpc_web_request)
      grpc_web_request = framing.unframe_request(grpc_web_request)
      grpc_web_request = serialization.deserialize_request(grpc_web_request)
      grpc_web_response = execute_request(grpc_web_request)
      grpc_web_response = serialization.serialize_response(grpc_web_response)
      grpc_web_response = framing.frame_response(grpc_web_response)
      text_coder.encode_response(grpc_web_response)
    end

    private

    def execute_request(request)
      service_method_sym = request.service_method.to_s.underscore

      begin
        response = request.service.send(service_method_sym, request.body)
      rescue => e
        response = e # Return exception as body if one is raised
      end
      ::GRPCWeb::GRPCWebResponse.new(response_content_type(request), response)
    end

    # Use Accept header value if specified, otherwise use request content type
    def response_content_type(request)
      if request.accept.nil? || ANY_CONTENT_TYPES.include?(request.accept)
        request.content_type
      else
        request.accept
      end
    end
  end
end
