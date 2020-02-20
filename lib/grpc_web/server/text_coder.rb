# frozen_string_literal: true

require 'base64'
require 'grpc_web/content_types'
require 'grpc_web/grpc_web_response'
require 'grpc_web/grpc_web_request'

# Placeholder
module GRPCWeb::TextCoder
  class << self
    include ::GRPCWeb::ContentTypes

    def decode_request(request)
      return request unless BASE64_CONTENT_TYPES.include?(request.content_type)

      # Body can be several base64 "chunks" concatenated together
      base64_chunks = request.body.scan(%r{[a-zA-Z0-9+/]+={0,2}})
      decoded = base64_chunks.map { |chunk| Base64.decode64(chunk) }.join
      ::GRPCWeb::GRPCWebRequest.new(
        request.service, request.service_method, request.content_type, request.accept, decoded,
      )
    end

    def encode_response(response)
      return response unless BASE64_CONTENT_TYPES.include?(response.content_type)

      encoded = Base64.strict_encode64(response.body)
      ::GRPCWeb::GRPCWebResponse.new(response.content_type, encoded)
    end
  end
end
