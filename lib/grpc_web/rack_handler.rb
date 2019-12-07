# frozen_string_literal: true

require 'rack/request'
require 'grpc_web/grpc_request_processor'

module GRPCWeb
  module RackHandler
    NOT_FOUND = 404
    POST = 'POST'

    class << self
      def call(service, service_method, env)
        rack_request = Rack::Request.new(env)
        return not_found_response(rack_request.path) unless post?(rack_request)

        response = GRPCRequestProcessor.process(service, service_method, rack_request)
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

      def not_found_response(path)
        [NOT_FOUND, { 'Content-Type' => "text/plain", "X-Cascade" => "pass" }, ["Not Found: #{path}"]]
      end

      def invalid_response(message)
        [422, {'Content-Type' => 'text/plain'}, ["Invalid request format: #{message}"]]
      end

      def error_response
        [500, {'Content-Type' => 'text/plain'}, ["Request failed with an unexpected error."]]
      end
    end
  end
end
