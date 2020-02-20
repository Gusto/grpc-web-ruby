# frozen_string_literal: true

module GRPCWeb::ContentTypes
  DEFAULT_CONTENT_TYPE = 'application/grpc-web'
  PROTO_CONTENT_TYPE = 'application/grpc-web+proto'
  JSON_CONTENT_TYPE = 'application/grpc-web+json'
  TEXT_CONTENT_TYPE = 'application/grpc-web-text'
  TEXT_PROTO_CONTENT_TYPE = 'application/grpc-web-text+proto'

  BASE64_CONTENT_TYPES = [TEXT_CONTENT_TYPE, TEXT_PROTO_CONTENT_TYPE].freeze
  ALL_CONTENT_TYPES = [
    DEFAULT_CONTENT_TYPE,
    PROTO_CONTENT_TYPE,
    JSON_CONTENT_TYPE,
    TEXT_CONTENT_TYPE,
    TEXT_PROTO_CONTENT_TYPE,
  ].freeze
  ANY_CONTENT_TYPES = ['*/*', '', nil].freeze
end
