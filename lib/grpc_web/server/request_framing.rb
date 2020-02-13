# frozen_string_literal: true

require 'grpc_web/grpc_web_response'
require 'grpc_web/grpc_web_request'
require 'grpc_web/message_framing'

# Framing concerns for handling a request on the server
module GRPCWeb::RequestFraming
  class << self
    def unframe_request(request)
      frames = message_framing.unpack_frames(request.body)
      ::GRPCWeb::GRPCWebRequest.new(
        request.service, request.service_method, request.content_type, request.accept, frames,
      )
    end

    def frame_response(response)
      frames = message_framing.pack_frames(response.body)
      ::GRPCWeb::GRPCWebResponse.new(response.content_type, frames)
    end

    private

    def message_framing
      ::GRPCWeb::MessageFraming
    end
  end
end
