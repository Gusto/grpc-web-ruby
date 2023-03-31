# frozen_string_literal: true

require 'grpc_web/content_types'
require 'grpc_web/grpc_web_response'
require 'grpc_web/server/request_framing'
require 'grpc_web/server/error_callback'
require 'grpc_web/server/message_serialization'
require 'grpc_web/server/text_coder'
require 'grpc_web/server/grpc_response_encoder'
require 'grpc_web/server/grpc_request_decoder'

# Placeholder
module GRPCWeb::GRPCRequestProcessor
  class << self
    include ::GRPCWeb::ContentTypes

    def process(grpc_call)
      encoder = GRPCWeb::GRPCResponseEncoder

      grpc_web_response = execute_request(grpc_call)
      encoder.encode(grpc_web_response)
    end

    private

    def execute_request(grpc_call)
      decoder = GRPCWeb::GRPCRequestDecoder

      service_method = ::GRPC::GenericService.underscore(grpc_call.request.service_method.to_s)
      begin
        # Check arity to before passing in metadata to make sure that server can handle the request.
        # This is to ensure backwards compatibility
        if grpc_call.request.service.method(service_method.to_sym).arity == 1
          response = grpc_call.request.service.send(
            service_method,
            decoder.decode(grpc_call.request).body,
          )
        else
          response = grpc_call.request.service.send(
            service_method, decoder.decode(grpc_call.request).body, grpc_call,
          )
        end
      rescue StandardError => e
        ::GRPCWeb.on_error.call(e, grpc_call.request.service, grpc_call.request.service_method)
        response = e # Return exception as body if one is raised
      end
      ::GRPCWeb::GRPCWebResponse.new(response_content_type(grpc_call.request), response)
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
