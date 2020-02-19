# frozen_string_literal: true

require 'google/protobuf'
require 'rack'
require 'rack/request'
require 'grpc_web/content_types'
require 'grpc_web/grpc_web_request'
require 'grpc_web/server/error_callback'
require 'grpc_web/server/grpc_request_processor'

# Placeholder
module GRPCWeb::RackHandler
  NOT_FOUND = 404
  UNSUPPORTED_MEDIA_TYPE = 415
  INTERNAL_SERVER_ERROR = 500
  ACCEPT_HEADER = 'HTTP_ACCEPT'

  class << self
    include ::GRPCWeb::ContentTypes

    def call(service, service_method, env)
      rack_request = Rack::Request.new(env)
      return not_found_response(rack_request.path) unless rack_request.post?
      return unsupported_media_type_response unless valid_content_types?(rack_request)

      content_type = rack_request.content_type
      accept = rack_request.get_header(ACCEPT_HEADER)
      body = rack_request.body.read
      request = GRPCWeb::GRPCWebRequest.new(service, service_method, content_type, accept, body)
      response = GRPCWeb::GRPCRequestProcessor.process(request)

      [200, { 'Content-Type' => response.content_type }, [response.body]]
    rescue Google::Protobuf::ParseError => e
      invalid_response(e.message)
    rescue StandardError => e
      ::GRPCWeb.on_error.call(e, service, service_method)
      error_response
    end

    private

    def valid_content_types?(rack_request)
      return false unless ALL_CONTENT_TYPES.include?(rack_request.content_type)

      accept = rack_request.get_header(ACCEPT_HEADER)
      return true if ANY_CONTENT_TYPES.include?(accept)

      ALL_CONTENT_TYPES.include?(accept)
    end

    def not_found_response(path)
      [
        NOT_FOUND,
        { 'Content-Type' => 'text/plain', 'X-Cascade' => 'pass' },
        ["Not Found: #{path}"],
      ]
    end

    def unsupported_media_type_response
      [
        UNSUPPORTED_MEDIA_TYPE,
        { 'Content-Type' => 'text/plain' },
        ['Unsupported Media Type: Invalid Content-Type or Accept header'],
      ]
    end

    def invalid_response(message)
      [422, { 'Content-Type' => 'text/plain' }, ["Invalid request format: #{message}"]]
    end

    def error_response
      [
        INTERNAL_SERVER_ERROR,
        { 'Content-Type' => 'text/plain' },
        ['Request failed with an unexpected error.'],
      ]
    end
  end
end
