# frozen_string_literal: true

require 'rack/request'
require 'grpc_web/content_types'
require 'grpc_web/grpc_request_processor'
require 'grpc_web/grpc_web_request'

module GRPCWeb
  module RackHandler
    NOT_FOUND = 404
    UNSUPPORTED_MEDIA_TYPE = 415
    INTERNAL_SERVER_ERROR = 500
    POST = 'POST'
    ACCEPT_HEADER = 'HTTP_ACCEPT'

    class << self
      include ::GRPCWeb::ContentTypes

      def call(service, service_method, env)
        rack_request = Rack::Request.new(env)
        return not_found_response(rack_request.path) unless post?(rack_request)
        return unsupported_media_type_response unless valid_content_types?(rack_request)

        request_format = rack_request.content_type
        accept = rack_request.get_header(ACCEPT_HEADER)
        body = rack_request.body.read
        request = GRPCWebRequest.new(service, service_method, request_format, accept, body)
        response = GRPCRequestProcessor.process(request)

        [200, {'Content-Type' => response.content_type}, [response.body]]

      rescue Google::Protobuf::ParseError => e
        invalid_response(e.message)
      # rescue => e
      #   error_response
      end

      private

      def post?(rack_request)
        rack_request.request_method == POST
      end

      def valid_content_types?(rack_request)
        return false unless ALL_GRPC_CONTENT_TYPES.include?(rack_request.content_type)
        accept = rack_request.get_header(ACCEPT_HEADER)
        return true if ANY_CONTENT_TYPES.include?(accept)
        return ALL_GRPC_CONTENT_TYPES.include?(accept)
      end

      def not_found_response(path)
        [NOT_FOUND, { 'Content-Type' => "text/plain", "X-Cascade" => "pass" }, ["Not Found: #{path}"]]
      end

      def unsupported_media_type_response
        [UNSUPPORTED_MEDIA_TYPE, {'Content-Type' => 'text/plain'}, ['Unsupported Media Type: Invalid Content-Type or Accept header']]
      end

      def invalid_response(message)
        [422, {'Content-Type' => 'text/plain'}, ["Invalid request format: #{message}"]]
      end

      def error_response
        [INTERNAL_SERVER_ERROR, {'Content-Type' => 'text/plain'}, ["Request failed with an unexpected error."]]
      end
    end
  end
end
