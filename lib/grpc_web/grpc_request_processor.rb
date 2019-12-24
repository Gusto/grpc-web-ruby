# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'grpc_web/content_types'
require 'grpc_web/grpc_web_response'
require 'grpc_web/message_serialization'
require 'grpc_web/text_coder'

module GRPCWeb::GRPCRequestProcessor
  class << self
    include ::GRPCWeb::ContentTypes

    def process(grpc_web_request)
      text_coder = ::GRPCWeb::TextCoder
      serialization = ::GRPCWeb::MessageSerialization

      grpc_web_request = text_coder.decode_request(grpc_web_request)
      grpc_web_request = serialization.deserialize_request(grpc_web_request)
      grpc_web_response = call_service(grpc_web_request)
      grpc_web_response = serialization.serialize_response(grpc_web_response)
      text_coder.encode_response(grpc_web_response)
    end

    private

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
  end
end
