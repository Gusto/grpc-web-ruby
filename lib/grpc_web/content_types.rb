# frozen_string_literal: true

module GRPCWeb::ContentTypes
  GRPC_CONTENT_TYPE = 'application/grpc-web'
  GRPC_PROTO_CONTENT_TYPE = 'application/grpc-web+proto'
  GRPC_JSON_CONTENT_TYPE = 'application/grpc-web+json'
  GRPC_TEXT_CONTENT_TYPE = 'application/grpc-web-text'
  GRPC_TEXT_PROTO_CONTENT_TYPE = 'application/grpc-web-text+proto'

  BASE64_CONTENT_TYPES = [GRPC_TEXT_CONTENT_TYPE, GRPC_TEXT_PROTO_CONTENT_TYPE].freeze
  ALL_GRPC_CONTENT_TYPES = [
    GRPC_CONTENT_TYPE,
    GRPC_PROTO_CONTENT_TYPE,
    GRPC_JSON_CONTENT_TYPE,
    GRPC_TEXT_CONTENT_TYPE,
    GRPC_TEXT_PROTO_CONTENT_TYPE,
  ].freeze
  ANY_CONTENT_TYPES = ['*/*', ''].freeze
end
