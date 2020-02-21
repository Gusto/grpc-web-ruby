# frozen_string_literal: true

require 'grpc_web/content_types'
require 'grpc_web/grpc_web_response'
require 'grpc_web/server/request_framing'
require 'grpc_web/server/error_callback'
require 'grpc_web/server/message_serialization'
require 'grpc_web/server/text_coder'

# Placeholder
module GRPCWeb::GRPCRequestProcessor
  class << self
    include ::GRPCWeb::ContentTypes

    def process(grpc_web_request)
      text_coder = ::GRPCWeb::TextCoder
      framing = ::GRPCWeb::RequestFraming
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
      service_method = ::GRPC::GenericService.underscore(request.service_method.to_s)

      begin
        response = request.service.send(service_method, request.body)
      rescue StandardError => e
        ::GRPCWeb.on_error.call(e, request.service, request.service_method)
        response = e # Return exception as body if one is raised
      end
      ::GRPCWeb::GRPCWebResponse.new(response_content_type(request), response)
    end

    # Use Accept header value if specified, otherwise use request content type
    def response_content_type(request)
      if UNSPECIFIED_CONTENT_TYPES.include?(request.accept)
        request.content_type
      else
        request.accept
      end
    end
  end
end
